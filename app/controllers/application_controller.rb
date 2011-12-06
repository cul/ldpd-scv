require "base64"
require "blacklight"
require "ruby-prof"
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  unloadable
  include Blacklight::Controller

  layout "application"

  helper_method :user_session, :current_user, :fedora_config, :solr_config, :relative_root # share some methods w/ views via helpers
  helper :all # include all helpers, all the time
  before_filter :check_new_session, :af_solr_init

  def af_solr_init
    ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
  end

  def current_user
    return @current_user if defined?(@current_user)
    
    if current_user_session
      @current_user = current_user_session.user
    else
      @current_user = false
    end
    @current_user
  end

  def current_user_session
    return @user_session if defined?(@user_session)
    @user_session = UserSession.find
  end

  protected

  def check_new_session
    if(params[:new_session])
      current_user.set_personal_info_via_ldap
      current_user.save
    end
  end

  def require_user
    unless current_user
      store_location
      redirect_to new_user_session_path
      return false
    end
  end

  def require_staff
    if current_user
      unless current_user.cul_staff
        redirect_to access_denied_url  
      end
    else
      store_location
      redirect_to new_user_session_path
      return false
    end
  end
  
  def require_admin
    if current_user
      unless current_user.admin
        redirect_to access_denied_url  
      end
    else
      store_location
      redirect_to new_user_session_path
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to root_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def openlayers_base
   @olbase ||= 'http://www.columbia.edu/cu/libraries/inside/projects/imaging/jsonp-openlayers'
  end
  def openlayers_js 
   @oljs ||= openlayers_base + '/lib/OpenLayers.js'
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
    stylesheet_links << ['yui', 'jquery/ui-lightness/jquery-ui-1.8.1.custom.css', 'application',{:plugin=>:blacklight, :media=>'all'}]
    stylesheet_links << ['zooming_image', 'accordion', {:media=>'all'}]
    stylesheet_links << ['scv']
    javascript_includes << ['jquery-1.4.2.min.js', 'jquery-ui-1.8.1.custom.min.js', { :plugin=>:blacklight } ]
    javascript_includes << ['accordion', 'zooming_image']
    extra_head_content << [stylesheet_tag(openlayers_css, :media=>'all'), javascript_tag(openlayers_js)]
  end

  def http_client
    unless @http_client
      @http_client ||= HTTPClient.new
    end
    @http_client
  end

end
