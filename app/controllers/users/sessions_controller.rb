class Users::SessionsController < Devise::SessionsController
  include Scv::OmniauthHelperBehavior

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

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
