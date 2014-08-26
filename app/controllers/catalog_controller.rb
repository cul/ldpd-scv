# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'blacklight/solr'
require 'blacklight/solr/request'
require 'blacklight/solr/document'

class CatalogController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Cul::Scv::FacetExtras
  include Cul::Scv::BlacklightConfiguration
  include CatalogHelper
  
  configure_blacklight do |config|
    configure_for_scv(config)
  end

  layout 'application'
  
  before_filter :require_staff
  before_filter :cache_docs,  :only=>[:index, :show]
  before_filter :af_object, :only=>[:show]
  after_filter :uncache_docs, :only=>[:index, :show]
  
  # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
  # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
  # which is used in the #show action here.
  rescue_from Blacklight::Exceptions::InvalidSolrID, :with => :invalid_solr_id_error

  
  # When RSolr::RequestError is raised, the rsolr_request_error method is executed.
  # The index action will more than likely throw this one.
  # Example, when the standard query parser is used, and a user submits a "bad" query.
  rescue_from RSolr::Error::Http, :with => :rsolr_request_error
  
  # single document image resource
  def image
  end
  
  # single document availability status (true/false)
  def status
  end
  
  # single document availability info
  def availability
  end
  
  # collection/search UI via Google maps
  def map
  end

  def cache_docs
    Thread.current[:doc_cache] = {}
  end

  def uncache_docs
    Thread.current[:doc_cache].clear
    Thread.current[:doc_cache] = nil
  end

  def show
    @response, @document = get_solr_response_for_doc_id
    if zoomable?(@document)
          extra_head_content << [stylesheet_tag(openlayers_css, :media=>'all'), javascript_tag(zooming_js)]
    end

    respond_to do |format|
      format.html {setup_next_and_previous_documents}

      format.json { render json: {response: {document: @document}}}

      @document.export_formats.each_key do | format_name |
          format.send(format_name.to_sym) {render :text => @document.export_as(format_name), :layout=>false}
      end
    end
  end
end
