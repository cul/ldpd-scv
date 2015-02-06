module Scv::OmniauthHelperBehavior
  # override so that database_authenticatable can be removed
  def new_session_path(scope)
    new_user_session_path
  end
  def omniauth_provider_key
    @omniauth_provider_key ||= Scv::Application.cas_configuration_opts[:provider]
  end
end