source 'http://rubygems.org'
gem 'ruby-prof'
gem 'rails', '~>4.1'
gem 'actionpack-action_caching'
gem 'dalli'
gem 'rack-handlers'
gem 'sqlite3'
gem 'blacklight', '~> 5.7.2'
# pegging kaminari to fix a paging bug introduced in 0.16.0
gem 'kaminari', '0.15.1'
gem 'arel'
gem 'actionmailer'
gem 'sass'
gem 'sass-rails', '~>4.0.2'
gem 'bootstrap-sass', '>= 3.2'
gem 'jquery-rails', '>= 3.0'
gem 'jquery-ui-rails'
gem "unicode", :platforms => [:mri_18, :mri_19]
gem "hydra-head", "~>7"
gem 'active_fedora_finders', '~>0.5.0'
gem "active_fedora_relsint", :git=>'git://github.com/cul/active_fedora_relsint.git', :branch=>'master'
gem 'cancan'
gem 'columnize'
gem 'crack'
gem 'cul_image_props'
#gem 'cul_scv_hydra', :path=>'/Users/ba2213/Github/cul_scv_hydra'
gem 'cul_hydra', '~>1.0'
gem 'cul_omniauth', :git=>'git://github.com/cul/cul_omniauth.git', :branch=>'master'
#gem 'cul_omniauth', :path=>'/Users/ba2213/Github/cul/cul_omniauth', :branch=>'master'
gem 'devise'
gem 'database_cleaner'
gem 'diff-lcs'
gem 'haml'
gem 'httpclient', '2.1.6.1'
gem 'httparty'
gem 'i18n'
gem 'json_pure', '>1.4.3'
gem 'loggable'
gem 'mime-types'
gem 'multipart-post'
gem 'mysql'
gem 'net-ldap', '>=0.1.1'
gem 'nokogiri' # Default to using the version required by Blacklight
gem 'om', '>=1.4.0'
gem 'rack'
gem 'rack-test'
gem 'rake'
# gem 'rcov'
gem 'rsolr' # Default to using the version required by Blacklight
gem 'rsolr-ext' # Default to using the version required by Blacklight
gem 'rubydora', '>=1.8.0'
gem 'RedCloth', '>=4.2.3'
gem 'scrypt'
gem 'solr-ruby' 
gem 'term-ansicolor'
gem 'xml-simple'
gem 'block_helpers'
gem 'sanitize'
gem 'thread', :git=>'git@github.com:meh/ruby-thread.git', :branch=>'master'
group :development, :test do
  gem 'capistrano', '~>2.x'
  gem 'capybara'
  gem 'yard'
  gem 'jettywrapper', ">= 1.4.1"
  gem 'rspec', '>= 2.0.0'  
  gem 'rspec-rails', '>= 2.0.0' # rspec-rails 2.0.0 requires Rails 3.
  gem 'rspec-collection_matchers'
  gem 'poltergeist'
  gem 'cucumber', '>=0.8.5'
  gem 'cucumber-rails', '>=1.0.0', :require => false
  gem 'gherkin'
  gem 'factory_girl'
end
gem 'thin', group: :development
# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails'
  gem 'uglifier', '>= 1.0.3'
end
group :scv_dev, :scv_test, :scv_prod do
  gem 'mysql2'
end