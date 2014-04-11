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

namespace :cul do
  namespace :util do
	  namespace :jjay do
      desc 'Fix some jp2 DS mimeTypes'
      task :fix_types => :environment do
        d_tmp = Fake.new(nil)
        ds_uris = []
        open(ENV['DS_LIST']) do |blob|
          blob.each {|line| ds_uris << line.strip unless line =~ /^#/}
        end
        total = ds_uris.length
        ctr = 0
        ds_uris.each do |ds_uri|
          ds = ds_at(ds_uri, d_tmp)
          ctr += 1
          changed = false
          if ds.label =~ /\.png$/
            ds.dsLabel= 'zoom.jp2'
            changed = true
          end
          if ds.mimeType != 'image/jp2'
            ds.mimeType = 'image/jp2'
            changed = true
          end
          begin
            if changed
              ds.save
              logger.info "updated #{ds_uri} (#{ctr} of #{total})"
            else
              logger.info "verified #{ds_uri} (#{ctr} of #{total})"
            end
          rescue Exception => e
            logger.error "errored #{ds_uri} (#{ctr} of #{total}) #{e.message}"
          end
        end
      end
    end
  end
end
