require 'cul'
require 'nokogiri'
require 'rsolr-ext'
require 'thread/pool'

class SolrCollection
  attr_reader :pid, :solr
  def initialize(pid, solr_url)
    @pid = pid
    @solr = RSolr.connect :url=>solr_url
    @colon = Regexp.new(':')
  end
  def fedora_query(pid)
    objuri = "info:fedora/#{pid}"
    query = <<-ITQL
     select $child $parent from <#ri> where walk($child <http://purl.oclc.org/NET/CUL/memberOf> <#{objuri}> and $child <http://purl.oclc.org/NET/CUL/memberOf> $parent)
    ITQL
    opts = {}
    opts[:format] = "json"
    opts[:lang] = "itql"
    #query = URI.escape(query)
    #query = "lang=itql&format=json&limit=&query=" + query
    puts query
    ri_resp = Cul::Fedora.repository.itql query, opts
    puts ri_resp
    tuples = JSON::parse(ri_resp)['results']
    _nodes = [pid]
    len = 'info:fedora/'.length
    tuples.each { |tuple|
      _nodes << tuple['child'][len..tuple['child'].length]
    }
    _paths = _nodes.uniq
    self.paths=_paths
  end
  def run_solr_query(query, start, rows, fl)
    query_parms = {}
    query_parms[:fq]=query
    query_parms[:start]=start
    query_parms[:rows]=rows
    query_parms[:fl]= "*"
    query_parms[:wt]= :ruby
    #query_parms[:qt]= :document
    resp_json = solr.get('select', {:params=>query_parms})
    resp_json
  end
  def paths()
    if !(@paths)
      fedora_query(pid)
    end
    @paths
  end
  def paths=(arg1)
    @paths=arg1
  end
  def ids()
    if !(@ids)
      @ids = []
      if (paths.length == 0)
        p "Warning: No paths given to find SolrCollection members"
      end
      query_pid = "info:fedora\\/#{@pid}".gsub(@colon, '\:')
      q = "cul_member_of_ssim:#{query_pid}"
      puts q
      size = 10
      start = 0
      while
        response=run_solr_query(q,start,size,:id)["response"]
        numFound = response["numFound"].to_i
        docs = response["docs"] | []
        @ids.concat( docs.collect{|doc| doc["id"] })
        start = @ids.length
        break if start >= numFound
      end
    end
    @ids
  end
  def members()
    paths
  end
end

def logger
  Rails.logger
end

namespace :cul do
  namespace :scv do
    namespace :users do

     desc "load the fedora configuration"
     task :configure => :environment do
       env = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'development'
       yaml = YAML::load(File.open("config/fedora_ri.yml"))[env]
       ENV['RI_URL'] ||= yaml['riurl'] 
       ENV['RI_QUERY'] ||= yaml['riquery'] 
     end

     desc "add unis to SCV by setting cul_staff to TRUE"
     task :add_user => :configure do
       if ENV['UNIS']
         unis = ENV['UNIS'].split(/\s/)
         User.set_staff!(unis)
       end
     end

     desc "remove unis from SCV by setting cul_staff to FALSE"
     task :remove_user => :configure do
       if ENV['UNIS']
         unis = ENV['UNIS'].split(/\s/)
         User.unset_staff!(unis)
       end
     end

     desc "remove unis from SCV by deleting the user record"
     task :delete_user => :configure do
       if ENV['UNIS']
         unis = ENV['UNIS'].split(/\s/)
         unis.each { |uni|
           u = User.find_by_login(uni)
           u.delete
         }
       end
     end
    end
    namespace :solr do

     desc "load the fedora configuration"
     task :configure => :environment do
       env = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'development'
       yaml = YAML::load(File.open("config/fedora_ri.yml"))[env]
       ENV['RI_URL'] ||= yaml['riurl'] 
       ENV['RI_QUERY'] ||= yaml['riquery'] 
     end

     desc "optimize solr index"
     task :optimize => :configure do
       solr_config = YAML::load('config/solr.yml')
       puts "optimizing #{solr_config[:url]}"
       Blacklight.solr.optimize
       puts "optimized..."
       Blacklight.solr.commit
       puts "committed..."
     end

     desc "delete all this collections children from index"
     task :delete_from => :configure do
       solr_url = ENV['SOLR'] || Blacklight.solr_config[:url]
       p "deleting from PID #{ENV['COLLECTION_PID']}"
       collection = SolrCollection.new(ENV['COLLECTION_PID'],solr_url)
       delete_array = collection.ids
       p "delete_array.length: #{delete_array.length}"
       if (delete_array.length == 0)
         logger.info "no deletes necessary; exiting"
         exit
       end
       deletes = 0
       delete_array.each do |id|
         logger.info "delete: #{id}"
         ActiveFedora::SolrService.instance.conn.delete_by_id(id)
         deletes += 1
       end
       ActiveFedora::SolrService.instance.conn.commit
     end
     desc "delete this list from Solr"
     task :delete => :configure do
        delete_array = []
        deletes = 0
        if ENV['PID']
          delete_array << ENV['PID']
        end
        if ENV['PID_LIST']
          open(ENV['PID_LIST']) do |blob|
            blob.each {|line| delete_array << line.strip}
          end
        end
        delete_array.each do |id|
          logger.info "delete: #{id}"
          ActiveFedora::SolrService.instance.conn.delete_by_id(id)
          deletes += 1
        end
        ActiveFedora::SolrService.instance.conn.commit

     end
     desc "index objects from a CUL fedora repository"
     task :index => :configure do
       urls_to_scan = case
       when ENV['PID_LIST']
         url_array = []
         File.readlines(ENV['PID_LIST']).each {|pid| url_array << pid.strip}
         url_array
       when ENV['COLLECTION_PID']
         solr_url = ENV['SOLR'] || Blacklight.solr_config[:url]
         collection = BagAggregator.search_repo(identifier: ENV['COLLECTION_PID']).first
         raise "Could not find #{ENV['COLLECTION_PID']}" if collection.nil?
         collection_pid = collection.pid
         logger.info "indexing collection #{collection_pid} from ID #{ENV['COLLECTION_PID']}"
         collection = SolrCollection.new(collection_pid,solr_url)
         url_array = collection.paths.dup
       when ENV['PID']
         url_array = ENV['PID'].split(',')
       when ENV['SAMPLE_DATA']
         File.read(File.join(Rails.root,"test","sample_data","cul_fedora_index.json"))
       when ENV['JSON']
         url_array = JSON::parse(ENV['JSON'])        
       else
         logger.info "No input options given!"
         url_array = []
       end

       logger.info "#{url_array.size} URLs to scan."

       

       solr_url = ENV['SOLR'] || Blacklight.solr_config[:url]
       logger.info "Using Solr at: #{solr_url}"
       
       update_uri = URI.parse(solr_url.gsub(/\/$/, "") + "/update")
       logger.info "indexing documents into index: #{url_array.length}"
       ActiveFedora::SolrService.instance.conn.commit
       show_error = true
       ctr = 0
       results = {}
       pool = Thread.pool(2)
       [GenericResource.name, ContentAggregator.name, BagAggregator.name ]

       url_array.each do |pid|
         ctr += 1

         pool.process(pid, ctr, url_array.length, results) do |id, current, total, r_cache|
           begin
             base_obj = ActiveFedora::Base.find(id, :cast=>true)
             ActiveFedora::SolrService.add(base_obj.to_solr, softCommit: false)
             if ctr % 100 == 0
               ActiveFedora::SolrService.instance.conn.commit
             end
             r_cache[id] = :success
             logger.info "index: #{id} #{current} of #{total}"
           rescue Exception => e
             r_cache[id] = :error
             logger.error "error: #{id} #{current} of #{total} : #{e.message}"
             logger.warn(e.backtrace.join("\n"))
             begin
              ActiveFedora::SolrService.instance.conn.delete_by_id(id)
              logger.info "deleted: #{id} on error"
             rescue Exception => e
              logger.warn "delete failed: #{id} on error"
             end
           end
         end
       end
       pool.shutdown
       ActiveFedora::SolrService.instance.conn.commit
       
      successes = 0
      errors = 0
      results.each {|id, result| (result == :success) ? successes += 1 : errors += 1 }
      logger.info "#{successes} URLs scanned successfully; #{errors} errors."

     end
      task :reindex => :configure do
        solr_query = {'dc_type_teim' => 'interactiveresource', 'fl' => 'id', 'rows' => 50}
        response = ActiveFedora::SolrService.instance.conn.find(solr_query)
        ctr = 0
        total = 0
        results = {}
        [GenericResource.name, ContentAggregator.name, BagAggregator.name ]
        while docs = response.docs and !docs.empty?
          pool = Thread.pool(2)
          url_array = docs.map {|doc| doc['id']}
          total += url_array.length
          docs = []
          url_array.each do |pid|
            ctr += 1

            pool.process(pid, ctr, total, results) do |id, current, total, r_cache|
              begin
                base_obj = ActiveFedora::Base.find(id, :cast=>true)
                docs << base_obj.to_solr
              rescue Exception => e
                r_cache[id] = :error
                logger.error "error: #{id} #{current} of #{total} : #{e.message}"
                logger.warn(e.backtrace.join("\n"))
                begin
                 ActiveFedora::SolrService.instance.conn.delete_by_id(id)
                 logger.info "deleted: #{id} on error"
                rescue Exception => e
                 logger.warn "delete failed: #{id} on error"
                end
              end
            end
          end
          pool.shutdown
          ActiveFedora::SolrService.instance.conn.add(docs)
          ActiveFedora::SolrService.instance.conn.commit
          docs.each {|doc| results[doc[:id]] = :success}
          logger.info "indexed #{ctr} of #{total}"
          response = ActiveFedora::SolrService.instance.conn.find(solr_query)
        end
        
        successes = 0
        errors = 0
        results.each {|id, result| (result == :success) ? successes += 1 : errors += 1 }
        logger.info "#{successes} URLs scanned successfully; #{errors} errors."
      end
    end
  end
end
