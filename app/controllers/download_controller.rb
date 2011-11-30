require 'net/http'
class DownloadController < ApplicationController
  before_filter :require_staff
  filter_access_to :fedora_content, :attribute_check => true,
                   :model => nil, :load_method => :download_from_params
  caches_action :cachecontent, :expires_in => 7.days,
    :cache_path => proc { |c|
      c.params
    }

  def download_headers(pid, dsid)
    h_cd = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    h_ct = Cul::Fedora.repository.datastream_dissemination({:pid => pid, :dsid => dsid, :method => :head})["Content-Type"].to_s
    {"Content-Disposition" => h_cd, "Content-Type" => h_ct}
  end

  def cachecontent
    #url = Cul::Fedora::ResourceIndex.config[:riurl] + "/get/" + params[:uri]+ "/" + params[:block]

    #cl = http_client
    #h_cd = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    #h_ct = Cul::Fedora.repository.datastream_dissemination({:pid => params[:uri], :dsid => params[:block], :method => :head})["Content-Type"].to_s
    #h_ct = cl.head(url).header["Content-Type"].to_s
    headers.delete "Cache-Control"
    headers.merge! download_headers(params[:uri], params[:block])
    
    render :status => 200, :text => cl.get_content(url)
  end
  def download_from_params
    unless defined?(@download)
      pid = params[:uri]
      ds = params[:block]
      r_obj = Cul::Fedora::Objects::BaseObject.new({:pid_s => pid},http_client)
      triples = r_obj.triples
      @download = DownloadObject.new
      triples.each { |triple|
        predicate = triple["predicate"]
        if predicate.eql? "http://purl.org/dc/elements/1.1/format"
          @download.mime_type=triple["object"]
        elsif predicate.eql? "info:fedora/fedora-system:def/model#hasModel"
          @download.content_models.push(triple["object"])
        end
      }
    end
    params[:object] = @download
  end
  def fedora_content
    #url = Cul::Fedora::ResourceIndex.config[:riurl] + "/get/" + params[:uri]+ "/" + params[:block]
    #cl = http_client
    #h_cd = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    #h_ct = cl.head(url).header["Content-Type"].to_s
    #h_ct = Cul::Fedora.repository.datastream_dissemination({:pid => params[:uri], :dsid => params[:block], :method => :head})["Content-Type"].to_s
    dl_hdrs = download_headers(params[:uri], params[:block])
    text_result = nil

    case params[:download_method]
    when "download"
      dl_hdrs["Content-Disposition"] = "attachment; " + dl_hdrs["Content-Disposition"] 
    when "show_pretty"
      if dl_hdrs["Content-Type"].include?("xml") || params[:print_binary_octet]
        
        xsl = Nokogiri::XSLT(File.read(Rails.root.join("app/stylesheets/pretty-print.xsl")))
        xml = Nokogiri::XML.parse(Cul::Fedora.repository.datastream_dissemination(:pid => params[:uri], :dsid => params[:block]))
        text_result = xsl.apply_to(xml).to_s
      else
        text_result = "Non-xml content streams cannot be pretty printed."
      end
    end
    headers.merge! dl_hdrs
    if text_result
      headers["Content-Type"] = "text/plain"
      render :text => text_result
    else
      ds_parms = {:pid => params[:uri], :dsid => params[:block]}
      logger.info "rubydora_params = #{ds_parms.inspect}"
      self.response_body =  Cul::Fedora::Streamer.new(Cul::Fedora.repository, ds_parms)
    # in Rails 3.1.x, we could do this:
    #  block_response = Proc.new { |res|
    #    res.read_body do |seg|
    #      puts seg.length
    #      send_data seg
    #    end
    #  }
    #  Cul::Fedora.repository.datastream_dissemination ds_parms, &block_response
    end
  end

  class DownloadObject
    attr_reader :content_models, :mime_type
    attr_writer :mime_type
    def initialize ()
      @content_models = []
      @mime_type = nil
    end
  end
end


