set :rails_env, "scv_dev"
set :domain,      "bronte.cul.columbia.edu"
set :application, "scv_dev"
set :deploy_to,   "/opt/passenger/#{application}/"
set :user, "deployer"
set :scm_passphrase, "Current user can full owner domains."

role :app, domain
role :web, domain
role :db,  domain, :primary => true

