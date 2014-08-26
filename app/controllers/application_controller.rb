# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base

  # Adds a few additional behaviors into the application controller 
  # Please be sure to implement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  include Blacklight::Controller
  include Cul::Scv::Controller
  include ApplicationHelper

  layout false

  helper_method :user_session, :current_user, :fedora_config, :solr_config, :relative_root # share some methods w/ views via helpers
  helper :all # include all helpers, all the time
  before_filter :check_new_session #, :af_solr_init

  def af_solr_init
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end

  def af_object
    @object ||= begin
      if params[:id]
        ActiveFedora::Base.find(params[:id], :cast=>true)
      else
        nil
      end
    end
  end

  def store_location
    session[:return_to] = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def openlayers_base
   @olbase ||= 'https://iris.cul.columbia.edu/openlayers'
  end
  def openlayers_js 
   @oljs ||= openlayers_base + '/lib/OpenLayers.js'
  end
  def zooming_js
    ActionController::Base.helpers.asset_path('zooming_image.js')
  end
  def openlayers_css
   @olcss ||= openlayers_base + '/theme/default/style.css'
  end

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  def javascript_tag(href)
    '<script src="' + href + '" type="text/javascript"></script>'
  end
  def stylesheet_tag(href, args)
    '<link href="' + href + '" rel="stylesheet" type="text/css" media="' + args[:media] + '" />'
  end
  def default_html_head
    #stylesheet_links << ['jquery/ui-lightness/jquery-ui-1.8.1.custom.css']
    #stylesheet_links << ['zooming_image', 'accordion', {:media=>'all'}]
    #stylesheet_links << ['scv']
    #javascript_includes << ['jquery-1.4.2.min.js', 'jquery-ui-1.8.1.custom.min.js', { :plugin=>:blacklight } ]
    #javascript_includes << ['accordion', 'zooming_image']
  end

end
