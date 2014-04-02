set :default_stage, "passenger_dev"
set :stages, %w(passenger_dev passenger_test passenger_prod)

require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'date'

default_run_options[:pty] = true

set :scm, :git
set :git_enable_submodules, 1
set :deploy_via, :remote_cache
set :repository,  "git@github.com:cul/cul-scv.git"
set :application, "scv"
set :use_sudo, false

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "mkdir -p #{current_path}/tmp/cookies"
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :symlink_shared do
    run "ln -nfs #{deploy_to}shared/secret_token.rb #{release_path}/config/initializers/secret_token.rb"
    run "ln -nfs #{deploy_to}shared/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{deploy_to}shared/fedora_credentials.yml #{release_path}/config/fedora_credentials.yml"
    run "ln -nfs #{deploy_to}shared/fedora.yml #{release_path}/config/fedora.yml"
    run "ln -nfs #{deploy_to}shared/solr.yml #{release_path}/config/solr.yml"
    run "ln -nfs #{deploy_to}shared/app_config.yml #{release_path}/config/app_config.yml"
    run "ln -nfs #{deploy_to}shared/role_map_#{rails_env}.yml #{release_path}/config/role_map_#{rails_env}.yml"
    run "mkdir -p #{release_path}/db"
    run "ln -nfs #{deploy_to}shared/#{rails_env}.sqlite3 #{release_path}/db/#{rails_env}.sqlite3"
  end

  desc "Compile assets"
  task :assets do
    #run "cd #{release_path}; RAILS_ENV=#{rails_env} bundle exec compass install bootstrap"
    run "cd #{release_path}; RAILS_ENV=#{rails_env} bundle exec rake assets:clean assets:precompile"
  end


end


after 'deploy:update_code', 'deploy:symlink_shared', 'deploy:assets'