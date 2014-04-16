require 'rubydora'
module Cul
module Fedora
  require 'cul/fedora/url_helper_behavior'
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
    ActiveFedora.fedora_config.credentials
  end
  def self.connection
    @connection ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.fedora_config.credentials)
  end

  def self.repository
    @repository ||= begin
      repo = connection.connection
      repo.extend(RubydoraPatch)
      repo
    end
  end

  def self.ds_for_uri(fedora_uri, fake_obj=nil)
    p = fedora_uri.split('/')
    fake_obj = fake_obj.nil? ? FakeObject.new(p[1]) : fake_obj.spawn(p[1])
    Rubydora::Datastream.new(fake_obj, p[2])
  end

  class FakeObject
    attr_accessor :pid
    def initialize(pid, isNew=false)
      @pid = pid
      @isNew = isNew
    end
    def new_record?
      @isNew
    end
    def connection
      Cul::Fedora.connection
    end    
    def repository
      Cul::Fedora.repository
    end
    def spawn(pid)
      s = FakeObject.new(pid)
      s.connection= connection
      s.repository= repository
      s
    end
    protected
    def connection=(connection); @connection = connection; end
    def repository=(repo); @repository = repo; end
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
