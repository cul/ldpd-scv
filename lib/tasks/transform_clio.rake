require 'open-uri'
module Transform
  def self.link_to_clio(id,xml=false)
    if id
      "http://clio.columbia.edu/catalog/#{id}#{xml ? ".marcxml" : ''}"
    else
      nil
    end
  end
  def self.mods_for(id)
    if id
      temp_file = Tempfile.new(id)
      begin
        if (link = link_to_clio(id,true))
          open(link) do |src|
            open(temp_file.path,'wb') {|out| out.write(src.read)}
          end
          xsl_path = File.join(Rails.root,'config','xsl','marc_to_mods.xsl')
          doc   = Nokogiri::XML(File.read(temp_file.path))
          xslt  = Nokogiri::XSLT(File.read(xsl_path))
          return xslt.transform(doc)
        end
      ensure
        temp_file.unlink
      end
    else
      return nil
    end
  end
end
module Pids
  def self.exists?(pid)
    begin
      return ActiveFedora::Base.exists? pid
    rescue
      return false
    end
  end
  def self.next_pid(namespace="ldpd")
    ActiveFedora::Base.fedora_connection[0] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials)
    repo = ActiveFedora::Base.fedora_connection[0].connection
    pid = nil
    begin
      pid = repo.mint(namespace: namespace)
    end while self.exists? pid
    pid
  end
  def parse_csv(path)

  end
end

class Clio
  attr_accessor :id
  attr_reader :dc_id
  def initialize(id)
    self.id=id
  end

  def id=(id)
    id = id.to_s
    id = id.strip || id
    if id =~ /^\d+$/
      @id = id
      @dc_id = nil
    else
      raise "Bad CLIO id #{id}"
    end
  end 
  def dc_id
    @dc_id ||= "clio.#{self.id}"
  end
  def aggregator(create = false)
    dc_id = "clio.#{id}"
    @aggregator ||= ContentAggregator.search_repo(identifier: dc_id).first
    was_new = !!@aggregator
    if create
      unless @aggregator
        @aggregator = ContentAggregator.new(pid: Pids.next_pid)
      end
    end
    if @aggregator
      dc = @aggregator.datastreams['DC']
      dc_changed = false
      unless dc.term_values(:dc_type).include? 'InteractiveResource'
        dc.update_values([:dc_type]=>'InteractiveResource')
        dc_changed = true
      end
      dc_ids = dc.term_values(:dc_identifier)
      unless dc_ids.include? dc_id
        dc_ids << dc_id
        dc.update_values([:dc_identifier]=>dc_ids)
        dc_changed = true
      end
      dc.content_will_change! if dc_changed
      @aggregator.save
      puts "#{was_new ? 'Created' : 'Updated'} #{@aggregator.pid} for #{dc_id}"
    end
    @aggregator
  end

  def update!
    cagg = self.aggregator(true)
    if cagg
      mods_content = Transform.mods_for(self.id)
      temp_file = Tempfile.new('mods')
      open(temp_file.path,'wb') {|out| out.write(mods_content)}
      descMetadata = cagg.datastreams['descMetadata']
      ng_xml = Nokogiri::XML(open(temp_file.path))
      descMetadata.ng_xml = ng_xml
      cagg.save
      puts "Updated #{cagg.pid} descMetadata for #{dc_id}"
      ns = {'mods'=>'http://www.loc.gov/mods/v3'}
      mods_node = ng_xml.xpath('/mods:mods',ns).first
      raise 'no mods node' unless mods_node
      title = descMetadata.sort_title
      short_title = title[0...255]
      dc = cagg.datastreams['DC']
      unless dc.term_values(:dc_title).include? short_title
        dc.update_values([:dc_title] => short_title)
        cagg.label = short_title
        dc_changed = true
      end
      dc.content_will_change! if dc_changed
      cagg.save
      puts "Updated #{cagg.pid} for #{dc_id}"
    end
  end
end

namespace :scv do

  namespace :transform do
    desc "configure AF"
    task :configure => :environment do
      ENV['RAILS_ENV'] ||= 'development'
      ActiveFedora.init :fedora_config_path =>"config/fedora.yml", :solr_config_path => "config/solr.yml"
    end
    task :fetch => :configure do
      id = ENV['id']
      mods_content = Transform.mods_for(id)
      mods_ng = Nokogiri::XML.read_memory(mods_content)
      ns = {'mods'=>'http://www.loc.gov/mods/v3','xmlns'=>'http://www.loc.gov/mods/v3'}
      mods_node = mods_ng.xpath('/mods:mods',ns).first
      puts 'No mods root node' unless mods_node
      open('mods.xml','wb') {|out| out.write(mods_content)}
    end
    task :associate=> :configure do
      ids = ENV['id'] ? {ENV['id'] => []} : {}
      if ENV['csv']
        csv = []
        open(ENV['csv']) do |blob|
          blob.each {|line| line.strip!; csv << line}
        end
        csv_map = {}
        csv.each do |line|
          parts = line.split(',')
          parts[0].strip!
          if parts[0] =~ /^\d+$/
            ids[parts[0]] = parts[2..-1].collect {|x| x.strip!; x}
          end
        end
      end
      begin
        ids.each do |id, children|
          clio = Clio.new(id)
          internal_uri = BagAggregator.search_repo(identifier: 'ldpd.misc').first.internal_uri
          cagg = clio.aggregator
          if cagg
            unless cagg.relationships(:cul_member_of).include? internal_uri
              cagg.add_relationship(:cul_member_of, internal_uri)
              cagg.save
            end
          else
          end
        end
      rescue => e
        puts 'Error: ' + e.message
        puts e.backtrace
      end

    end

    task :clio => :configure do
      ids = ENV['id'] ? {ENV['id'] => []} : {}
      if ENV['csv']
        csv = []
        open(ENV['csv']) do |blob|
          blob.each {|line| line.strip!; csv << line}
        end
        csv_map = {}
        csv.each do |line|
          parts = line.split(',')
          parts[0].strip!
          if parts[0] =~ /^\d+$/
            ids[parts[0]] = parts[2..-1].collect {|x| x.strip!; x}
          end
        end
      end
      begin
        ids.each do |id, children|
          clio = Clio.new(id)
          clio.update!
          children.each do |child|
            child.strip!
            unless child.empty?
              gr = ActiveFedora::Base.find(child)
              if gr.is_a? GenericResource
                unless gr.relationships(:cul_member_of).include? clio.aggregator.internal_uri
                  gr.add_relationship(:cul_member_of,clio.aggregator.internal_uri)
                  gr.save
                end
              end
            end
          end
        end
      rescue => e
        puts 'Error: ' + e.message
        puts e.backtrace
      end

    end

    task :bfs => :configure do
      src = '/cul/cul3/ldpd/example/jp2/978N48.jp2'
      dc_id = File.basename(src)
      mimetype = 'image/jp2'
      module Cul::Scv::Hydra::ActiveFedora
        RESOURCE_TYPE = (URI.parse("http://purl.oclc.org/NET/CUL/Resource"))
      end
      gr = GenericResource.search_repo(identifier: dc_id).first
      unless gr
        gr = GenericResource.new(pid: 'ldpd:490929')
        gr.datastreams['DC'].update_values([:dc_identifier]=>'978N48#image')
        gr.datastreams['DC'].update_values([:dc_title]=>'Image of CLIO_6666510')
        gr.datastreams['DC'].update_values([:dc_format]=>mimetype)
        gr.datastreams['DC'].update_values([:dc_type]=>'StillImage')
        gr.save
      end
      ds = gr.datastreams['content']
      if !ds or ds.new?
        ds = gr.create_datastream(ActiveFedora::Datastream, 'content', :dsLocation=>"file:#{src}", :controlGroup => 'E', :mimeType=>mimetype, :dsLabel=>src)
        gr.add_datastream(ds)
        ds.save
      end
      # width = 12345 , height = 5461, extent = 8574750
      changed = false
      rels_int = gr.rels_int
      if rels_int.relationships(ds,:image_width).blank?
        rels_int.add_relationship(ds,:image_width, 12345)
        changed = true
      end
      if gr.rels_int.relationships(ds,:image_length).blank?
        rels_int.add_relationship(ds,:image_length, 5461)
        changed = true
      end
      if gr.rels_int.relationships(ds,:extent).blank?
        rels_int.add_relationship(ds,:extent, 8574750)
        changed = true
      end
      if gr.rels_int.relationships(ds,:foaf_zooming).blank?
        rels_int.add_relationship(ds,:foaf_zooming, ds)
        changed = true
      end
      rels_int.content = rels_int.serialize! if changed
      gr.save
    end
  end

end
