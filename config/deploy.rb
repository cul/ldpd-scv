set :default_stage, "passenger_dev"
set :stages, %w(passenger_dev passenger_test passenger_prod)

require 'capistrano/ext/multistage'
default_run_options[:pty] = true

set :scm, :git
set :repository,  "git@github.com:cul/cul-scv.git"
set :application, "scv"
set :use_sudo, false

namespace :deploy do
  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :symlink_shared do
    run "ln -nfs #{deploy_to}shared/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{deploy_to}shared/fedora_credentials.yml #{release_path}/config/fedora_credentials.yml"
    run "ln -nfs #{deploy_to}shared/fedora.yml #{release_path}/config/fedora.yml"
    run "ln -nfs #{deploy_to}shared/solr.yml #{release_path}/config/solr.yml"
    run "ln -nfs #{deploy_to}shared/app_config.yml #{release_path}/config/app_config.yml"
  end

end


after 'deploy:update_code', 'deploy:symlink_shared'
