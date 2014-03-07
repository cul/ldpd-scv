require 'net/http'
require 'cul_scv_hydra'
require 'cul'
class DownloadController  < ActionController::Base
  include Cul::Scv::Controller

  before_filter :require_staff
  #filter_access_to :fedora_content, :attribute_check => true,
  #                 :model => nil, :load_method => :download_from_params
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
    response.headers.delete "Cache-Control"
    obj = GenericResource.find(params[:uri])
    dsid = params[:block]
    dl_hdrs = download_headers({:pid=>params[:uri], :dsid=>params[:block]})
    dl_hdrs["Content-Type"] = obj.datastreams[dsid].mimeType || 'binary/octet-stream'
    dl_hdrs["Content-Disposition"] = "inline; filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    response.headers.merge! dl_hdrs
    ds_parms = {:pid => params[:uri], :dsid => params[:block]}
    response.headers["Last-Modified"] = Time.now.to_s
    obj.datastreams[params[:block]].stream(self)
  end

  def download_from_params
    unless defined?(@download)
      pid = params[:uri]
      dsid = params[:block]
      @resource = GenericResource.find(pid)
      @download = DownloadObject.new
      @resource.ids_for_outbound(:has_model).each { |triple|
        @download.content_models << "info:fedora/#{triple}"
      }
      dc_format = @resource.dc.term_values(:dc_format)
      if dc_format and dc_format.length > 0
        @download.mime_type=dc_format.first
      end
    end
    params[:object] = @download
  end
  def fedora_content
    dl_opts = {:pid=>params[:uri], :dsid=>params[:block]}
    text_result = nil
    pid = params[:uri]
    dsid = params[:block]
    @resource = GenericResource.find(pid) unless defined?(@resource)
    dl_hdrs = {}
    dl_hdrs["Content-Type"] = @resource.datastreams[dsid].mimeType || 'binary/octet-stream'

    case params[:download_method]
    when "download"
      dl_hdrs["Content-Disposition"] = "attachment; filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    when "show_pretty"
      if dl_hdrs["Content-Type"].include?("xml") || params[:print_binary_octet]
        
        xsl = Nokogiri::XSLT(File.read(Rails.root.join("app/stylesheets/pretty-print.xsl")))
        xml = @resource.datastreams[dsid].content
        xml = Nokogiri::XML.parse(xml, nil, 'UTF-8')
        text_result = xsl.apply_to(xml).to_s
      elsif dl_hdrs["Content-Type"] =~ /te?xt/
        text_result = @resource.datastreams[dsid].content
      else
        text_result = "Non-xml content streams cannot be pretty printed. (#{dl_hdrs.inspect})"
      end
    else # "show"
      dl_hdrs["Content-Disposition"] = "inline; filename=""#{CGI.escapeHTML(params[:filename].to_s)}""" 
    end
    response.headers.merge! dl_hdrs
    if text_result
      response.headers["Content-Type"] = "text/plain; charset=utf-8"
      render :text => text_result
    else
      ds_parms = {:pid => params[:uri], :dsid => dsid}
      response.headers["Last-Modified"] = Time.now.to_s
      ds = Rubydora::Datastream.new(@resource.inner_object, dsid)
      size = params[:file_size] || params['file_size']
      size ||= ds.dsSize
      size ||= rels_int_size(@resource, dsid)
      size ||= rels_ext_size(@resource, dsid)
      unless size and size.to_i > 0
        response.headers["Transfer-Encoding"] = "chunked"
      else
        response.headers["Content-Length"] = size
      end
      self.response_body = ds.stream
#      @resource.datastreams[dsid].stream(self)
    end
  end

  def rels_int_size(obj, dsid)
    rels = obj.datastreams["RELS-INT"]
    return nil unless (rels and not rels.new?)
    triples = rels.relationships(obj.datastreams[dsid], :extent)
    return nil unless triples
    return triples.first.to_s.to_i
  end

  def rels_ext_size(obj, dsid)
    return nil unless dsid == 'CONTENT' # the only datastream we ever did this for
    triples = obj.relationships(:extent)
    return nil unless triples
    return triples.first.to_s.to_i
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


