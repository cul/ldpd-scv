require 'blacklight'
require 'active-fedora'
class CatalogController < ApplicationController
  unloadable
  include Blacklight::Catalog
  include Blacklight::SolrHelper
  
  configure_blacklight do |config|
    Scv::BlacklightConfiguration.configure(config)
    puts config.inspect
  end

  before_filter :require_staff
  before_filter :search_session, :history_session
  before_filter :delete_or_assign_search_session_params,  :only=>:index
  before_filter :adjust_for_results_view, :only=>:update
  after_filter :set_additional_search_session_values, :only=>:index
  
  # Whenever an action raises SolrHelper::InvalidSolrID, this block gets executed.
  # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
  # which is used in the #show action here.
  rescue_from Blacklight::Exceptions::InvalidSolrID, :with => :invalid_solr_id_error

  
  # When RSolr::RequestError is raised, the rsolr_request_error method is executed.
  # The index action will more than likely throw this one.
  # Example, when the standard query parser is used, and a user submits a "bad" query.
  rescue_from RSolr::Error::Http, :with => :rsolr_request_error
  
  def index
    puts Blacklight.solr_config.inspect
    puts self.solr_search_params({}).merge({}).inspect
    super
    #response.body = blacklight_config.inspect
    #return
  end

  def solr_search_params(extra_controller_params={})
    super.merge :per_page => (params[:per_page] || "10")
    #_params[:defType] = 'edismax'
  end
  
  # updates the search counter (allows the show view to paginate)
  def update
    session[:search][:counter] = params[:counter] unless session[:search][:counter] == params[:counter]
    session[:search][:display_members] = params[:display_members] unless session[:search][:display_members] == params[:display_members]
    redirect_to :action => "show"
  end
  
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
  
end
