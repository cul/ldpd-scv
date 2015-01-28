class Users::OmniAuthCallbacksController < Devise::OmniauthCallbacksController
  include Cul::OmniAuth::Callbacks
end