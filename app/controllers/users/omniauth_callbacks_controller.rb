class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Cul::Omniauth::Callbacks

  AUTOPROVISION = ["cul.cunix.local:columbia.edu","cul2.cunix.local:columbia.edu"]

  def set_staff?(affils=[])
    _result = false
    affils.each { |affil|
      _result ||= AUTOPROVISION.include?(affil)
    }
    _result
  end

  def affiliations(user, affils)
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