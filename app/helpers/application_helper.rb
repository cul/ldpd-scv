require 'cul'
module ApplicationHelper
  include Cul::Fedora::UrlHelperBehavior
  include Scv::ApplicationHelperBehavior
  include Scv::OmniauthHelperBehavior
end
