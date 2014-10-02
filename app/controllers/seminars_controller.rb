# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'blacklight/solr'
require 'blacklight/solr/request'
require 'blacklight/solr/document'

class SeminarsController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Cul::Scv::FacetExtras
  include Cul::Scv::BlacklightConfiguration
  include Cul::Scv::CatalogBehavior
  include CatalogHelper

  self.solr_search_params_logic += [:show_only_seminars]

  configure_blacklight do |config|
    configure_for_seminars(config)
  end

  layout 'application'
  
  before_filter :require_roles
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

  def self.authorized_roles
    #TODO move the role spec into config
    @authorized_roles ||= ["staff:scv.cul.columbia.edu","sh3040:users.scv.cul.columbia.edu"]
  end

  def initialize(*args)
    super(*args)
    self.class.parent_prefixes << 'catalog' # haaaaaaack to not reproduce templates
  end

  def show_only_seminars solr_parameters, user_parameters
  	solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "publisher_ssim:info\\:fedora\\/project\\:usem"
    unless user_parameters[:show_file_assets] == 'true'
      solr_parameters[:fq] << '-active_fedora_model_ssi:GenericResource'
    end
  end

end
