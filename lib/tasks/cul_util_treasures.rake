require 'cul'
require 'rubydora'
require 'active-fedora'
require 'tempfile'
class Fake
  attr_accessor :pid
  def initialize(pid, isNew=false)
    @pid = pid
    @isNew = isNew
  end
  def new_record?
    @isNew
  end
  def connection
    @connection ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.fedora_config.credentials)
  end    
  def repository
    @repository ||= connection.connection
  end
  def spawn(pid)
    s = Fake.new(pid)
    s.connection= connection
    s.repository= repository
    s
  end
  protected
  def connection=(connection); @connection = connection; end
  def repository=(repo); @repository = repo; end
end

def ds_at(fedora_uri, d_obj = nil)
  p = fedora_uri.split('/')
  d_obj = d_obj.nil? ? Fake.new(p[1]) : d_obj.spawn(p[1])
  Rubydora::Datastream.new(d_obj, p[2])
end

def logger
  Rails.logger
end

def structMetadata(cagg, override=false)
  ds = cagg.datastreams['structMetadata']
  unless override or ds.new?
    return ds
  end

  parts = cagg.parts(:response_format => :solr)
  sources = parts.collect {|part| part['dc_source_ssm'].first}
  if sources.length > 1 # try to structure
    structure = {}
    sources.each do |source|
      if source =~ /r\.tif/
        structure[:recto] = source.split('/')[-1].sub(/\.tif$/,'')
      elsif source =~ /v\.tif/
        structure[:verso] = source.split('/')[-1].sub(/\.tif$/,'')
      end
    end
    case structure.length
    when 2
      # make R/V map
      ds.label = 'Sides'
      ds.type = 'physical'
      ds.create_div_node(nil, {:order=>"1", :label=>"Recto", :contentids=>structure[:recto]})
      ds.create_div_node(nil, {:order=>"2", :label=>"Verso", :contentids=>structure[:verso]})
    when 1
      logger.warn("SKIPPED: #{cagg.pid} unexpected children")
      logger.info("#{sources.inspect}")
    when 0
      logger.info("SKIPPED: #{cagg.pid} doesn't appear to be R/V")
    end
  else
    logger.info("SKIPPED: #{cagg.pid} only has #{sources.length} children")
  end
  ds
end

def ds_rels(ds, rels_int)
  tempfile = Tempfile.new('temp',:encoding=>'ascii-8bit')
  tempfile.write(ds.content)
  tempfile.rewind
  image_properties = Cul::Image::Properties.identify(tempfile)
  if image_properties
    image_prop_nodes = image_properties.nodeset
    image_prop_nodes.each do |node|
      value = node["resource"] || node.text
      value = value.inspect if value.is_a? Cul::Image::Properties::Exif::Ratio 
      predicate = RDF::URI.new("#{node.namespace.href}#{node.name}")
      rels_int.clear_relationship(ds, predicate)
      rels_int.add_relationship(ds, predicate, value, node["resource"].blank?)
    end
  end
  tempfile.unlink
  image_properties
end

class DsProps
  attr_accessor :content, :format, :label
  def initialize(content, format, label)
    self.content=(content)
    self.format=(format)
    self.label=(label)
    raise 'content is required' if self.content.nil?
  end
end
namespace :cul do
  namespace :util do
	  namespace :treasures do
      desc 'attempts to build structMetadata'
      task :structMetadata => :environment do
        open(ENV['PID_LIST']) do |blob|
          blob.each do |pid|
            pid = pid.strip
            cagg = ContentAggregator.find(pid, :cast=>true)

            begin
              ds = structMetadata(cagg)
              if ds.changed?
                cagg.save
                logger.info("SUCCESS: #{cagg.pid}")
              end
            rescue Exception => e
              logger.error("ERROR: #{cagg.pid} #{e.message}")
              logger.info(e.backtrace)
            end
          end
        end
      end
      desc 'attempt to build a GenericResoure from sparse StaticImageAggregators'
      task :notiffs => :environment do
      	pid_list = ENV['PID_LIST'] || 'treasures_broken.txt'
        open(pid_list) do |blob|
          blob.each do |pid|
            pid = pid.strip
            sia = StaticImageAggregator.find(pid, :cast=>true)
            gr = sia.adapt_to(GenericResource)
            parts = sia.parts
            ds_map = {}
            format_map = {}
            long = 0
            parts.each do |part|
              p "#{part.pid}<#{part.class.name}>"
              width = part.relationships(:image_width)[0].to_s.to_i
              length = part.relationships(:image_length)[0].to_s.to_i
              ds_key = (width > length) ? width : length
              extent = part.relationships(:extent)[0]
              content = part.datastreams['CONTENT']
              format = ''
              if (content and !content.new?)
                format = content.mimeType()
              end
              label = part.datastreams['DC'].term_values(:dc_source).first || "web#{ds_key}.jpg"
              label = label.split('/')[-1]
              p "#{part.pid}<#{part.class.name}> #{width} x #{length}, #{format}, #{extent} bytes"
              tempfile = Tempfile.new('temp',:encoding=>'ascii-8bit')
              tempfile.write(content.content)
              tempfile.rewind
              ds_map[ds_key.to_s] = DsProps.new(tempfile, format, label)
              long = ds_key if (ds_key > long)
            end
            dsProps = ds_map.delete(long.to_s) unless long == 0
            if (dsProps)
              nouv = gr.create_datastream(ActiveFedora::Datastream, 'content', :controlGroup=>'M', :mimeType=>dsProps.format, :dsLabel=>dsProps.label)
              nouv.content = dsProps.content
              gr.add_datastream(nouv)
              p "added content"
            end
            ds_map.each do |k,v|
              nouv = gr.create_datastream(ActiveFedora::Datastream, "web#{k}", :controlGroup=>'M', :mimeType=>v.format, :dsLabel=>v.label)
              nouv.content = dsProps.content
              gr.add_datastream(nouv)
              p "added web#{k}"
            end
            gr.remove_relationship(:has_model,'info:fedora/ldpd:StaticImageAggregator')
            gr.add_relationship(:has_model, RDF::URI('info:fedora/ldpd:GenericResource'))
            gr.save;
            dsProps.content.unlink if dsProps and dsProps.content
            ds_map.each do |k,v|
              v.content.unlink if v.content
            end
          end
        end
      end
      task :rels => :environment do
        pid_list = ENV['PID_LIST'] || 'treasures_broken.txt'
        open(pid_list) do |blob|
          blob.each do |pid|
            pid = pid.strip
            sia = StaticImageAggregator.find(pid)
            gr = sia.adapt_to(GenericResource)
            parts = sia.parts
            ds_map = {}
            long = 0
            parts.each do |part|
              part.add_relationship(:cul_obsolete_from, sia)
              part.remove_relationship(:cul_member_of, sia)
              part.save
            end
            #gr.remove_relationship(:rdf_type, RDF::URI("http://purl.oclc.org/NET/CUL/Aggregator"))
            #gr.add_relationship(:rdf_type, RDF::URI("http://purl.oclc.org/NET/CUL/Resource"))
            ds_rels(gr.datastreams['content'], gr.rels_int)
            ds_rels(gr.datastreams['web200'], gr.rels_int)
            #gr.rels_int.add_relationship(gr.datastreams['web200'],:format_of,gr.datastreams['content'])
            #gr.rels_int.add_relationship(gr.datastreams['content'],:foaf_thumbnail,gr.datastreams['web200'])
            gr.save
          end
        end
      end
      task :tiffs => :environment do
        csv = ENV['CSV'] || 'treasures_broken.csv'
        open(csv) do |blob|
          blob.each do |line|
            line = line.strip
            parts = line.split(',')
            # "cagg","gr","note","match"
            old = ActiveFedora::Base.find(parts[1])
            new_gr = ActiveFedora::Base.find(parts[-1])
            cagg = ActiveFedora::Base.find(parts[0])
            old.remove_relationship(:cul_member_of, cagg.internal_uri)
            old.add_relationship(:foaf_depicts, cagg.internal_uri)
            old.save
            new_gr.add_relationship(:cul_member_of, cagg.internal_uri)
            new_gr.save
          end
        end
      end
    end
  end
end
