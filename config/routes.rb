Scv::Application.routes.draw do

  root :to => "catalog#index"
  blacklight_for :catalog, :seminars
  devise_for :users, :controllers => {
    omniauth_callbacks: "users/omniauth_callbacks",
  }

  resources :previews, only: :show, constraints: { id: /[^\?]+/ }

  resources :reports, only: :show

  resources :children, path: 'catalog/:parent_id/children', only: [:index, :show]


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
  get '/logged_out' => 'welcome#logout'
  # match '/thumbnail/:id', :to => 'thumbnail#get'
  resources :thumbs, only: [:show]
  resource :report
  
  get '/reports/preview/:category' => 'reports#preview', 
    :category => /(by_collection)/
  
  get '/catalog/:id/proxies' => 'catalog#show', as: :root_proxies
  get '/catalog/:id/proxies/*proxy_id' => 'catalog#show', as: :proxy

  get ':controller(/:action(/:id))'
  get ':controller/:action/:id.:format'

  devise_scope :user do
    get 'sign_in', :to => 'users/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end

  resources :sessions, controller: 'users/sessions'
end