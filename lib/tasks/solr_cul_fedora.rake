require 'cul'
require 'nokogiri'
require 'rsolr-ext'

class Node
  attr_reader :pid
  def initialize(pid)
    @pid = pid
    @children = {}
  end
  def add_child(cnode)
    @children[cnode.pid] = cnode
  end
  def children
    @children.values
  end
  def serialize
    if @children.length > 0
      @children.values.collect { |child|
        child.serialize.collect { |path|
          @pid + "/" + path
        }
      }.flatten
    else
      [@pid + "/"]
    end
  end
end
class SolrCollection
  attr_reader :pid, :solr
  attr_accessor :objects
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
    _children = []
    _nodes = {}
    tuples.each { |tuple|
      _p = tuple["parent"].sub("info:fedora/","")
      _c = tuple["child"].sub("info:fedora/","")
      _children << _c
      if not _nodes.has_key?(_p)
        _nodes[_p] = Node.new(_p)
      end
      if not _nodes.has_key?(_c)
        _nodes[_c] = Node.new(_c)
      end
      _nodes[_p].add_child( _nodes[_c])
    }
    _nodes.reject! {|key,node| _children.include? node.pid }
    _paths = []
    _nodes.each { |key,node|
      _paths.concat(node.serialize)
    }
    self.paths=_paths
    self.objects=_children
    self.objects << pid
  end
  def solr_query(query, start, rows, fl, collection_prefix=false)
    query_parms = {}
    query_parms[:q]=query
    query_parms[:start]=start
    query_parms[:rows]=rows
    query_parms[:fl]= "*"
    query_parms[:wt]= :ruby
    query_parms[:qt]= :document
    if (collection_prefix)
      query_parms[:facet]="on"
      query_parms["facet.field"]=:internal_h
      query_parms["facet.prefix"]=(collection_prefix + "*")
    end
    resp_json = solr.get('select', query_parms)
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
      paths.each{|path|
        q = path.gsub(@colon,'\:')
        if q.index('/') == 0
          q = q.slice(1,q.size - 1)
        end
        if q.rindex('/') < (q.length() - 1)
          q = q + '/'
        end
        q = "internal_h:" + q
        puts q
        size = 10
        start = 0
        while
          response=solr_query(q,start,size,:id)
          numFound = response["response"]["numFound"]
          docs = response["response"]["docs"] | []
          @ids.concat( docs.collect{|doc| doc["id"] })
          start += size
          break if start > numFound
        end
      }
    end
    @ids
  end
  def members()
    if !(@members)
      @members = []
        _members = objects().collect{|id| id.split('@')[0] }
        _members.compact!
        _members.uniq!
        @members |= _members
    end
    @members
  end
end
class Gatekeeper
  attr_reader :pids, :patterns
  def initialize(arg1)
    @pids = arg1
    @patterns = arg1.collect { |pid|
      Regexp.new('\b' + pid + '\b(\/)?')
    }
  end
  def allowed?(value)
    result = false
    patterns.each do |pattern|
      result |= (pattern =~ value)
    end
    result
  end
  def accept?(filedata)
    result = false
    if (patterns.length == 0)
      p "Warning: No allowable collection regex's"
    end
    doc = Nokogiri::XML::Document.parse(filedata,'utf-8')
    doc.xpath('//xmlns:field[@name="internal_h"]').each do |element|
      result |= allowed?element.content
    end
    result
  end
  def getInternalFacets(solr_url)
    # select_uri = base_uri + "/select"
    p solr_url
    results = []
    query_parms = {}
    query_parms[:q]="*:*"
    query_parms[:start]=0
    query_parms[:rows]=2
    query_parms[:facet]="on"
    query_parms["facet.field"]=[:internal_h]
    query_parms[:fl]= :internal_h
    query_parms[:wt]= :ruby
    query_parms[:qt]= :document
    solr = RSolr.connect :url=>solr_url
    colon = Regexp.new(':')
    pids.each { |pid|
      query_parms[:q]="id:#{pid.gsub(colon,'\:')}\b*"
      facet_json = solr.request('/select', query_parms)
      #facet_json = solr.get('select', query_parms)
      p facet_json
      # parse it
      facets = facet_json
      # pull all internal_h values, and check against allowed patterns
      facet_counts = facets['facet_counts']['facet_fields']['internal_h']
      facet_counts.flatten!
      facet_counts.each_with_index { |val, index|
        if (val.to_s.index('path-')==0):
          results << facet_counts[index + 1] 
        end
      }
    }
      # return filtered values
    results
  end
end
namespace :solr do
 namespace :cul do
   namespace :fedora do
# for each collection, the task needs to fetch the unlimited count, and then work through the pages
# for development, we should probably just hard-code a sheet of data urls
     desc "load the fedora configuration"
     task :configure => :environment do
       env = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'development'
       yaml = YAML::load(File.open("config/fedora_ri.yml"))[env]
       ENV['RI_URL'] ||= yaml['riurl'] 
       ENV['RI_QUERY'] ||= yaml['riquery'] 
       ALLOWED = Gatekeeper.new(yaml['collections'].split(';'))
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
           User.delete(:login=>uni)
         }
       end
     end

     desc "index objects from a CUL fedora repository"
     task :optimize => :configure do
       puts "optimizing #{SOLR_CONFIG[:url]}"
       Blacklight.solr.optimize
       puts "optimized..."
       Blacklight.solr.commit
       puts "committed..."
     end

     desc "index objects from a CUL fedora repository"
     task :index => :configure do
       delete_array = []
       urls_to_scan = case
       when ENV['URL_LIST']
         p "indexing url list #{ENV['URL_LIST']}"
         url = ENV['URL_LIST']
         uri = URI.parse(url) # where is url assigned?
         url_list = Net::HTTP.new(uri.host, uri.port)
         url_list.use_ssl = uri.scheme == 'https'
         urls = url_list.start { |http| http.get(uri.path).body }
         url_list.finish
         urls
       when ENV['COLLECTION_PID']
         p "indexing collection #{ENV['COLLECTION_PID']}"
         solr_url = ENV['SOLR'] || Blacklight.solr_config[:url]
         collection = SolrCollection.new(ENV['COLLECTION_PID'],solr_url)
         p collection.paths
         facet_vals = collection.paths.find_all { |val|
           ALLOWED.allowed?val
         }
         p facet_vals
         facet_vals = facet_vals.reject{|val|
           facet_vals.any?{|compare|
             (val != compare && val.index(compare) == 0)
           }
         }
         p facet_vals
         collection.paths=facet_vals
         collection.members
         delete_array = collection.ids
         query = sprintf(ENV['RI_QUERY'],ENV['COLLECTION_PID'])
         opts = {:format => 'json', :lang => 'itql'}
         members = Cul::Fedora.repository.itql query, opts
         members = JSON::parse(members)['results']
         members = members.collect {|member|
           member['member'].split('/')[1]
         }
         members |= collection.members
         url_array = members
       when ENV['PID']
         p "indexing pid #{ENV['PID']}"
         pid = ENV['PID']
         fedora_uri = URI.parse(ENV['RI_URL'])
         # < adding collections
         solr_url = ENV['SOLR'] || Blacklight.solr_config[:url]
         collection = SolrCollection.new(ENV['PID'],solr_url)
         facet_vals = collection.paths.find_all { |val|
           ALLOWED.allowed?val
         }
         facet_vals = collection.paths.find_all { |val|
           ALLOWED.allowed?val
         }
         facet_vals = facet_vals.reject{|val|
           facet_vals.any?{|compare|
             (val != compare && val.index(compare) == 0)
           }
         }
         collection.paths=facet_vals
         # adding collections >
         url_array = [pid]
       when ENV['SAMPLE_DATA']
         File.read(File.join(Rails.root,"test","sample_data","cul_fedora_index.json"))
       else
         p "No input options given!"
         url_array = []
       end

       url_array ||= JSON::parse(urls_to_scan)
       puts "#{url_array.size} URLs to scan."

       deletes = 0
       successes = 0

       solr_url = ENV['SOLR'] || Blacklight.solr_config[:url]
       puts "Using Solr at: #{solr_url}"
       
       update_uri = URI.parse(solr_url.gsub(/\/$/, "") + "/update")
       p "delete_array.length: #{delete_array.length}"
       #if (delete_array.length == 0)
       #  exit
       #end
       delete_array.each do |id|
         ActiveFedora::SolrService.instance.conn.delete(id)
         deletes += 1
       end
       ActiveFedora::SolrService.instance.conn.commit
       url_array.each do |pid|
         base_obj = ActiveFedora::Base.load_instance("info:fedora/#{pid}")
         ActiveFedora::ContentModel.known_models_for(base_obj).each do |model|
           puts "Found model #{model.to_s}"
           begin
             model_obj = model.load_instance("info:fedora/#{pid}")
             puts model_obj.to_solr
             model_obj.update_index
             successes += 1
           rescue Exception => e
              puts "#{update_uri} threw error #{e.message}"
           end
         end
       end

       puts "#{deletes} existing SOLR docs deleted prior to index"
       puts "#{successes} URLs scanned successfully."
       #if (successes > 0)
       #      Net::HTTP.start(update_uri.host, update_uri.port) do |http|
       #        msg = '<commit waitFlush="false" waitSearcher="false"></commit>'
       #        hdrs = {'Content-Type'=>'text/xml','Content-Length'=>msg.length.to_s}
       #        begin
       #           commit_res = http.post(update_uri.path, msg, hdrs)
       #           if commit_res.response.code == "200"
       #              puts 'commit successful'
       #           else
       #              puts "#{update_uri} received: #{commit_res.response.code}"
       #              puts "#{update_uri} msg: #{commit_res.response.message}"
       #           end
       #        rescue Exception => e
       #        end
       #      end
       #end
     end
   end
 end
end
