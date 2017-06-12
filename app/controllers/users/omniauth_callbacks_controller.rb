class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Cul::Omniauth::Callbacks

  AUTOPROVISION = [
    "CUNIX_cul","CUNIX_cul2","CUNIX_libinfosys",
    "cul.cunix.local:columbia.edu",
    "cul2.cunix.local:columbia.edu",
    "libinfosys.cunix.local:columbia.edu"    
  ]

  def developer
    @current_user ||= User.first_or_initialize(provider: 'developer', uid:request.env["omniauth.auth"][:uid].split('@')[0])

    sign_in_and_redirect @current_user, event: :authentication
  end

  def set_staff?(affils=[])
    _result = false
    affils.each { |affil|
      _result ||= AUTOPROVISION.include?(affil)
    }
    _result
  end

  def affils(user, affils)
    affiliations(user, affils)
  end

  def affiliations(user, affils)
    return unless user && user.login
    if set_staff?(affils)
      User.set_staff!([user.login])
      affils.push("staff:cul.columbia.edu")
    else
      User.unset_staff!([user.login])
    end
    affils.push("#{user.login}:users.cul.columbia.edu")
    if user.cul_staff
      affils.push("staff:cul.columbia.edu")
    end
    affils.uniq!
    roles = []
    affils.each { |rs|
      role = Role.find_by_role_sym(rs)
      if !role
        role = Role.create(:role_sym=>rs)
      end
      roles.push(role)
    }
    # delete the existing role associations
    user.roles.clear
    # add the new role associations
    user.roles=roles 
    user.save!

  end

end