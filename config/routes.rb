CulScv::Application.routes.draw do
  Blacklight.add_routes(self)

  root :to => 'catalog#index'

  devise_for :users

  resources :reports


  match '/download/fedora_content/:download_method/:uri/:block/:filename', 
    :to => 'download#fedora_content',
    :constraints => {
      :block => /(DC|CONTENT|SOURCE)/
      :uri => /.+/,
      :filename => /.+/,
      :download_method => /(download|show|show_pretty)/
    }
  match '/download/cache/:download_method/:uri/:block/:filename', 
    :to => 'download#cachecontent',
    :constraints => {
      :block => /(DC|CONTENT|SOURCE)/
      :uri => /.+/,
      :filename => /.+/,
      :download_method => /(download|show|show_pretty)/
    }
  match 'wind_logout', :to => 'welcome#logout'
  match '/access_denied', :to => 'welcome#access_denied'
  match '/thumbnail/:id', :to => 'thumbnail#get'

  resource :report
  
  match '/reports/preview/:category', :to => 'reports#preview', 
    :category => /(by_collection)/
  
  match ':controller(/:action(/:id))'
  match ':controller/:action/:id.:format'

end
