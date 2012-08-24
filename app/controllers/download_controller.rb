require 'net/http'
require 'cul_scv_hydra'
class DownloadController < ApplicationController
  before_filter :require_staff
  filter_access_to :fedora_content, :attribute_check => true,
                   :model => nil, :load_method => :download_from_params
  caches_action :cachecontent, :expires_in => 7.days,
    :cache_path => proc { |c|
      c.params
    }

  def download_headers(opts)
    opts = opts.merge({:method => :head})
    h_cd = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    h_ct = Cul::Fedora.repository.datastream_dissemination(opts)["Content-Type"].to_s
    if h_ct.empty? and ["DC", "RELS-EXT", "AUDIT", "descMetadata", "rightsMetadata"].include? opts[:dsid] #figure out why head isn't always returning type for DC
      h_ct = "text/xml"
    end
    {"Content-Disposition" => h_cd, "Content-Type" => h_ct}
  end

  def cachecontent
    headers.delete "Cache-Control"
    headers.merge! download_headers({:pid=>params[:uri], :dsid=>params[:block]})
    ds_parms = {:pid => params[:uri], :dsid => params[:block]}
    self.response_body =  Cul::Fedora::Streamer.new(Cul::Fedora.repository, ds_parms)
  end
  def download_from_params
    unless defined?(@download)
      pid = params[:uri]
      ds = params[:block]
      r_obj = Cul::Scv::Hydra::ActiveFedora::Model::DcDocument.load_instance(pid)
      @download = DownloadObject.new
      r_obj.ids_for_outbound(:has_model).each { |triple|
        @download.content_models << "info:fedora/#{triple}"
      }
      dc_format = r_obj.dc.term_values(:format)
      if dc_format and dc_format.length > 0
        @download.mime_type=dc_format.first
      end
    end
    params[:object] = @download
  end
  def fedora_content
    dl_opts = {:pid=>params[:uri], :dsid=>params[:block]}
    dl_hdrs = download_headers(dl_opts)
    text_result = nil

    case params[:download_method]
    when "download"
      dl_hdrs["Content-Disposition"] = "attachment; " + dl_hdrs["Content-Disposition"] 
    when "show_pretty"
      if dl_hdrs["Content-Type"].include?("xml") || params[:print_binary_octet]
        
        xsl = Nokogiri::XSLT(File.read(Rails.root.join("app/stylesheets/pretty-print.xsl")))
        xml = Cul::Fedora.repository.datastream_dissemination(dl_opts)
        if xml.respond_to? :read_body
          body = ""
          xml.read_body do |segment|
            body += segment
          end
          xml = body
        end
        xml = Nokogiri::XML.parse(xml, nil, 'UTF-8')
        text_result = xsl.apply_to(xml).to_s
      elsif dl_hdrs["Content-Type"].include?("txt")
        text_result = xml
      else
        text_result = "Non-xml content streams cannot be pretty printed. (#{dl_hdrs.inspect})"
      end
    end
    headers.merge! dl_hdrs
    if text_result
      headers["Content-Type"] = "text/plain; charset=utf-8"
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


