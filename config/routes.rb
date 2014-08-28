Scv::Application.routes.draw do

  root :to => "catalog#index"
  blacklight_for :catalog

  resources :previews, only: :show, constraints: { id: /[^\?]+/ }

  resources :reports, only: :show


  get '/download/fedora_content/:download_method/:uri/:block/:filename' => DownloadController.action(:fedora_content),
    :as => :fedora_content,
    :constraints => {
      :uri => /.+/,
      :filename => /.+/,
      :download_method => /(download|show|show_pretty)/
    }
  get '/download/cache/:download_method/:uri/:block/:filename' => DownloadController.action(:cachecontent),
    :as => :cache,
    :constraints => {
      :uri => /.+/,
      :filename => /.+/,
      :download_method => /(download|show|show_pretty)/
    }

  namespace :resolve do
    resources :catalog, only: [:show], constraints: { id: /[^\?]+/ } do
      resources :bytestreams, only: [:index, :show] do
        get 'content'=> 'bytestreams#content'
      end
    end
    resources :thumbs, only: [:show], constraints: { id: /[^\?]+/ }
    resources :bytestreams, path: 'catalog/:catalog_id/bytestreams', only: [:index, :show], constraints: { id: /[^\/]+/ }
  end

  get '/access_denied' => 'welcome#access_denied'
  # match '/thumbnail/:id', :to => 'thumbnail#get'
  resources :thumbs, only: [:show]
  resource :report
  
  get '/reports/preview/:category' => 'reports#preview', 
    :category => /(by_collection)/
  
  get ':controller(/:action(/:id))'
  get ':controller/:action/:id.:format'

  get '/login' =>'user_sessions#new', :as => 'new_user_session'
  get '/wind_logout' =>'user_sessions#destroy', :as => 'destroy_user_session'
end
