require 'rubydora'
module Cul
module Fedora
  require 'cul/fedora/resource_index'
  require 'cul/fedora/object'
  module RubydoraPatch
  # This module is just to patch Rubydora to make use of a streaming block
  # and to allow use of a head request here
    def datastream_dissemination options = {}, &block_response
      pid = options.delete(:pid)
      dsid = options.delete(:dsid)
      method = options.delete(:method)
      method ||= :get
      raise "no dsid! #{options.inspect}" unless dsid
      begin
        rsrc = client[url_for(datastream_url(pid, dsid) + "/content", options)]
        if block_given?
          rsrc.options[:block_response] = block_response
        end
        return rsrc.send(method)
      rescue RestClient::ResourceNotFound => e
        raise e
      rescue => e
        logger.error e.response if e.respond_to? :response
        logger.error e if not e.respond_to? :response
        logger.error e.backtrace.join("\n")
        raise "Error getting dissemination for datastream #{dsid} for object #{pid}. See logger for details"
      end
    end
  end
  #Rubydora::RestApiClient.extend(RubydoraPatch)
  def self.config_path
    File.join(Rails.root.to_s, 'config', 'fedora.yml')
  end
  def self.config
    @config ||= begin
      raise "Missing ActiveFedora configuration at #{config_path}" unless File.exists?(config_path)
      config = YAML::load(File.open(config_path))
      raise "The #{::Rails.env} environment settings were not found in the fedora.yml config" unless config[::Rails.env]
      config[::Rails.env].symbolize_keys
    end
  end
  def self.repository
    @repository ||= begin
      config = self.config.dup
      raise "No url given in Fedora config!\n#{config.inspect}" unless config[:url]
      repo = Rubydora::Repository.new(config)
      repo.extend(RubydoraPatch)
      repo
    end
  end
  class Streamer
    def initialize(parms)
      raise "Streamer requires opts[:dsid]" unless parms[:dsid]
      raise "Streamer requires opts[:pid]" unless parms[:pid]
      @rubydora_params = parms
    end
    # Rails 3 expects to iterate over the streamed segments
    # RestClient's block needs to close over the Rails block,
    # so we create it here in the iterator
    def each(&output_block)
      block_response =  Proc.new { |res|
        res.read_body do |seg|
          output_block.call(seg)
        end
      }
      Cul::Fedora.repository.datastream_dissemination @rubydora_params.dup, &block_response
    end
  end

end
end
