module Cul::Scv::Controller
  extend ActiveSupport::Concern

  def store_location
    session[:return_to] = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
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
      redirect_to user_omniauth_authorize_path(provider: :wind)
      return false
    end
  end

  def require_staff
    if current_user
      unless current_user.cul_staff
        redirect_to access_denied_url  
      end
    elsif !Rails.env.eql?('development')
      store_location
      redirect_to user_omniauth_authorize_path(provider: :wind)
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
      redirect_to user_omniauth_authorize_path(provider: :wind)
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

  def require_roles
    if current_user
      roles = self.class.authorized_roles
      okay = (roles.empty?) || (roles.include? '*')
      current_user.roles.each do |role|
        okay ||= roles.include?(role.role_sym.to_s)
      end
      unless okay
        redirect_to access_denied_url  
      end
    else
      store_location
      redirect_to user_omniauth_authorize_path(provider: :wind)
      return false
    end
  end

  def http_client
    unless @http_client
      @http_client ||= HTTPClient.new
    end
    @http_client
  end

end