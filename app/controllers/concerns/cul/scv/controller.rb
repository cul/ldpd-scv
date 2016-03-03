module Cul::Scv::Controller
  extend ActiveSupport::Concern

  protected

  def check_new_session
    if(current_user && params[:new_session])
      current_user.set_personal_info_via_ldap
      current_user.save
    end
  end

  def require_staff
    if current_user
      unless current_user.cul_staff
        access_denied  
        return false
      end
    elsif !Rails.env.eql?('development')
      store_location
      redirect_to_login
      return false
    end
  end

  def require_admin
    if current_user
      unless current_user.admin
        access_denied  
      end
    else
      store_location
      redirect_to_login
      return false
    end
  end

  def require_roles
    if can? :"#{controller_name.to_s}##{params[:action].to_s}", Cul::Omniauth::AbilityProxy
      return true
    else
      puts "#{current_user ? current_user.login : 'guest'} user cannot #{controller_name.to_s}##{params[:action].to_s}"
      if current_user
        access_denied
        return false
      end
    end
    store_location
    redirect_to_login
    return false
  end

  def redirect_to_login
    redirect_to user_omniauth_authorize_path(provider: omniauth_provider_key, url:session[:return_to])
  end

  def http_client
    unless @http_client
      @http_client ||= HTTPClient.new
    end
    @http_client
  end

  def omniauth_provider_key
    @omniauth_provider_key ||= Scv::Application.cas_configuration_opts[:provider]
  end

end