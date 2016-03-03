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
  include Cul::Scv::CatalogBehavior
  include CatalogHelper
  
  configure_blacklight do |config|
    configure_for_scv(config)
  end

  layout 'application'
  
  # only requiring roles on :index and :show to allow track action
  #before_filter :authenticate_user!, only:[:index, :show]
  before_filter :require_roles, only:[:index, :show]
  before_filter :cache_docs,  only:[:index, :show]
  before_filter :af_object, only:[:show]
  after_filter :uncache_docs, only:[:index, :show]
  
  # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
  # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
  # which is used in the #show action here.
  rescue_from Blacklight::Exceptions::InvalidSolrID, :with => :invalid_solr_id_error
  
  # When RSolr::RequestError is raised, the rsolr_request_error method is executed.
  # The index action will more than likely throw this one.
  # Example, when the standard query parser is used, and a user submits a "bad" query.
  rescue_from RSolr::Error::Http, :with => :rsolr_request_error

  def home
    (@response, @document_list) = get_search_results({})

    respond_to do |format|
      format.html { }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json do
        render json: render_search_results_as_json
      end

      additional_response_formats(format)
      document_export_formats(format)
    end
  end
end
