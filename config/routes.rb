Scv::Application.routes.draw do
  root :to => "catalog#index"

  Blacklight.add_routes(self)

  root :to => 'catalog#index'

  resources :reports


  match '/download/fedora_content/:download_method/:uri/:block/:filename', 
    :to => DownloadController.action(:fedora_content),
    :as => :fedora_content,
    :constraints => {
      :uri => /.+/,
      :filename => /.+/,
      :download_method => /(download|show|show_pretty)/
    }
  match '/download/cache/:download_method/:uri/:block/:filename', 
    :to => 'download#cachecontent',
    :as => :cache,
    :constraints => {
      :uri => /.+/,
      :filename => /.+/,
      :download_method => /(download|show|show_pretty)/
    }
  match 'wind_logout', :to => 'welcome#logout'
  match '/access_denied', :to => 'welcome#access_denied'
  # match '/thumbnail/:id', :to => 'thumbnail#get'
  resources :thumbnails
  resource :report
  
  match '/reports/preview/:category', :to => 'reports#preview', 
    :category => /(by_collection)/
  
  match ':controller(/:action(/:id))'
  match ':controller/:action/:id.:format'

  match '/login', :to =>'user_sessions#new', :as => 'new_user_session'
  match '/wind_logout', :to =>'user_sessions#destroy', :as => 'destroy_user_session'
end
