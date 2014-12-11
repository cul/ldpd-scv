require 'cul'
require 'rubydora'
require 'active-fedora'
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

namespace :cul do
  namespace :util do
	  namespace :lindquist do
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
      desc 'attempts to fix GR DC'
      task :dcid => :environment do
        open(ENV['PID_LIST']) do |blob|
          blob.each do |pid|
            pid = pid.strip
            cagg = ContentAggregator.find(pid, :cast=>true)
            parts = cagg.parts(:response_format => :solr)
            parts.each do |part|
              ids = part['dc_identifier_ssim']
              source = (part['dc_source_ssm'] and part['dc_source_ssm'].first)
              unless source
                logger.warn("SKIP #{pid} no source")
                next
              end
              id = source.split(/\/data\//)[-1]
              id = "apt://columbia.edu/burke_lindq/data/#{id}"
              pid = part['id']
              unless !ids or !id or ids.include? id
                gr = GenericResource.find(pid, cast: true)
                dc = gr.datastreams['DC']
                unless dc.term_values(:dc_identifier).include? id
                  vals = dc.term_values(:dc_identifier) + [id]
                  dc.update_indexed_attributes([:dc_identifier]=>vals)
                  dc.changed_attributes[:content] = true
                  gr.save
                  logger.info("SUCCESS #{pid} id: #{id}")
                end
              else
                logger.warn("SKIP #{pid} id: #{id} ids: #{ids}")
              end
            end
          end
        end
      end
    end
  end
end
