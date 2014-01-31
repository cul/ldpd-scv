require 'rubydora'
module Cul
module Fedora
  require 'cul/fedora/object'
  module RubydoraPatch
  # This module is just to patch Rubydora to make use of a streaming block
  # and to allow use of a head request here
    def itql query, options = {}
      self.risearch(query, {:lang => 'itql'}.merge(options))
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
    def initialize(repo, parms)
      raise "Streamer requires opts[:dsid]" unless parms[:dsid]
      raise "Streamer requires opts[:pid]" unless parms[:pid]
      @repo = repo
      @rubydora_params = parms
    # Rails 3.0.x calls the iterator twice. This flag should have no effect in 3.1.x
      @done = false
    end
    # Rails 3 expects to iterate over the streamed segments
    # RestClient's block needs to close over the Rails block,
    # so we create it here in the iterator
    def each(&output_block)
      return if @done
      block_response =  Proc.new { |res|
        res.read_body do |seg|
          output_block.call(seg)
        end
      }
      @repo.datastream_dissemination @rubydora_params.dup, &block_response
      @done = true
    end
  end

end
end
