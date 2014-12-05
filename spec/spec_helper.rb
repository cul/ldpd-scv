require 'yaml'
ENV["environment"] ||= 'test'
ENV["RAILS_ENV"] ||= 'test'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app','helpers'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app','models'))
libs = File.expand_path(File.dirname(__FILE__) + '/../lib/*.rb')
require File.expand_path("../../config/environment", __FILE__)
require 'blacklight'
require 'cul_scv_hydra'
require 'rspec/rails'
require 'rspec/collection_matchers'
require 'capybara/rspec'
require 'capybara/poltergeist'


Capybara.javascript_driver = :poltergeist

Capybara.register_driver :poltergeist do |app|
  options = {}

  options[:timeout] = 120 if RUBY_PLATFORM == "java"

  Capybara::Poltergeist::Driver.new(app, options)
end

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
end