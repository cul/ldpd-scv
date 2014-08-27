require File.expand_path('../boot', __FILE__)
require 'rails/all'
# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scv
  class Application < Rails::Application

    config.generators do |g|
      g.template_engine :haml
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # See: http://stackoverflow.com/questions/4928664/trying-to-implement-a-module-using-namespaces
    config.autoload_paths += %W(#{config.root}/lib)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif zooming_image.js application.css application.js)

  end
end
