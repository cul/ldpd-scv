require 'net/http'
require 'cul_scv_hydra'
require 'cul'
class DownloadController  < ActionController::Base
  include Cul::Scv::Controller

  helper_method :user_session, :current_user, :fedora_config, :solr_config, :relative_root # share some methods w/ views via helpers
  helper :all # include all helpers, all the time
  before_filter :check_new_session #, :af_solr_init

  before_filter :require_user
  filter_access_to :fedora_content, :attribute_check => true,
                   :model => nil, :load_method => :download_from_params
#  caches_action :cachecontent, :expires_in => 7.days,
#    :cache_path => proc { |c|
#      c.params
#    }

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
    if permitted_to? :fedora_content, obj, {:context => :download}
      dsid = params[:block]
      dl_hdrs = download_headers({:pid=>params[:uri], :dsid=>params[:block]})
      dl_hdrs["Content-Type"] = obj.datastreams[dsid].mimeType || 'binary/octet-stream'
      dl_hdrs["Content-Disposition"] = "inline; filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
      response.headers.merge! dl_hdrs
      ds_parms = {:pid => params[:uri], :dsid => params[:block]}
      response.headers["Last-Modified"] = Time.now.to_s
      obj.datastreams[params[:block]].stream(response)
    else
      redirect_to access_denied_url
    end
  end

  def download_from_params
    @download ||= begin
      pid = params[:uri]
      dsid = params[:block]
      @resource = GenericResource.find(pid)
      @download = download_object_for(@resource)
      dc = @resource.datastreams['DC']
      dc_format = dc.term_values(:dc_format)
      if dc_format and dc_format.length > 0
        @download.mime_type=dc_format.first
      end
      @download
    end
    params[:object] = @download
  end
  def fedora_content
    dl_opts = {:pid=>params[:uri], :dsid=>params[:block]}
    text_result = nil
    pid = params[:uri]
    dsid = params[:block]
    @resource ||= GenericResource.find(pid)
    @download ||=download_object_for(@resource)
    unless permitted_to? :fedora_content, @download, {:context => :download}
      redirect_to access_denied_url
      return
    end
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
      response.headers["Last-Modified"] = Time.now.to_s
      ds = Rubydora::Datastream.new(@resource.inner_object, dsid)
      size = rels_int_size(@resource, dsid)
      size ||= rels_ext_size(@resource, dsid)
      size ||= params[:file_size] || params['file_size']
      size ||= ds.dsSize
      if size and size.to_i > 0
        response.headers["Content-Length"] = [size]
      end
      response.headers["Content-Type"] = ds.mimeType

      repo = ActiveFedora::Base.connection_for_pid(pid)
      repo.datastream_dissemination(dl_opts) do |res|
        res.read_body do |seg|
          response.stream.write seg
        end
      end
      response.stream.close
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


  def download_object_for(generic_resource)
    opts = {}
    opts[:mime_type] = generic_resource.datastreams['content'].mimeType
    opts[:content_models] = generic_resource.relationships(:has_model).collect {|rel| rel.to_s}
    opts[:publisher] = generic_resource.relationships(:publisher).collect {|rel| rel.to_s}
    Cul::Scv::DownloadProxy.new(opts)
  end
end


