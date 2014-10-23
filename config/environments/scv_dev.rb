Scv::Application.configure do
# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
#config.consider_all_requests_local = false
config.action_controller.perform_caching             = true

config.eager_load = true

# Full error reports are disabled and caching is turned on.
config.consider_all_requests_local       = false
config.action_controller.perform_caching = true

# Enable Rack::Cache to put a simple HTTP cache in front of your application
# Add `rack-cache` to your Gemfile before enabling this.
# For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
# config.action_dispatch.rack_cache = true

# Disable Rails's static asset server (Apache or nginx will already do this).
config.serve_static_assets = false

# Compress JavaScripts and CSS.
config.assets.js_compressor = :uglifier
# config.assets.css_compressor = :sass

# Do not fallback to assets pipeline if a precompiled asset is missed.
config.assets.compile = false

# Generate digests for assets URLs.
config.assets.digest = true

# Version of your assets, change this if you want to expire all your assets.
config.assets.version = '1.0'

# See everything in the log (default is :info)
# config.log_level = :debug

# Use a different logger for distributed setups.
# config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

# Use a different cache store in production.
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and JavaScripts from an asset server.
# config.action_controller.asset_host = "http://assets.example.com"

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# config.assets.precompile += %w( search.js )

# Ignore bad email addresses and do not raise email delivery errors.
# Set this to true and configure the email server for immediate delivery to raise delivery errors.
# config.action_mailer.raise_delivery_errors = false


config.action_mailer.delivery_method = :sendmail
config.action_mailer.smtp_settings = {
  :location => "/usr/bin/sendmail",
  :arguments => '-i -t'
}
config.action_mailer.default_url_options = { :host => 'bronte.cul.columbia.edu' }
config.active_support.deprecation = :notify
# Use default logging formatter so that PID and timestamp are not suppressed.
config.log_formatter = ::Logger::Formatter.new
Haml::Template::options[:ugly] = true
end
