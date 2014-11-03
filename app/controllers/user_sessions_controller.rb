class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def new
    current_user_session.destroy if current_user_session
    @user_session = UserSession.new
    params[:login_with_wind] = true if UserSession.login_only_with_wind
    session[:return_to] = params[:return_to] || root_url
    @user_session.save 
  end

 
  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|  
      if result  
        session[:return_to] = nil if session[:return_to].to_s.include?("logout")
        redirect_back_or_default root_url  
      else  
        flash[:error] = "Unsuccessfully logged in."
        redirect_to wind_logout_url
        return
      end  
    end
  end
  
  def destroy
    current_user_session.destroy
    redirect_to wind_logout_url
  end

  # updates the search counter (allows the show view to paginate)
  def update
    if params[:counter]
      session[:search][:counter] = params[:counter] unless session[:search][:counter] == params[:counter]
    end
    if params[:display_members]
      session[:search][:display_members] = params[:display_members] unless session[:search][:display_members] == params[:display_members]
    end

    if params[:id]
      redirect_to :action => "show", :controller => :catalog, :id=>params[:id]
    else
      redirect_to :action => "index", :controller => :catalog
    end      
  end

  def wind_logout_url
    "https://#{UserSession.wind_host}/logout?passthrough=1&destination=" + root_url
  end
end
