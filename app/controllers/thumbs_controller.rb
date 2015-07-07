require 'actionpack/action_caching'
class ThumbsController < ActionController::Base

  include Hydra::Controller::ControllerBehavior
  include Cul::Hydra::Controller
  include Cul::Hydra::Thumbnails
  #caches_action :show, :expires_in => 7.days
  

end