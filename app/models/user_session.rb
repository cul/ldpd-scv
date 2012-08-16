require 'authlogic_wind'
class UserSession < Authlogic::Session::Base 
  unloadable
  wind_host "wind.columbia.edu"
  wind_service "culscv"
  auto_register true
  login_only_with_wind true

  AUTOPROVISION = ["cul.cunix.local:columbia.edu","cul2.cunix.local:columbia.edu"]

  def set_staff?(affils=[])
    _result = false
    affils.each { |affil|
      _result ||= AUTOPROVISION.include?(affil)
    }
    _result
  end

  def authenticate_with_wind
   
    if @record
      self.attempted_record = record

      if !attempted_record
        errors.add(:base,"Could not find user in our database.")
      end
    else
      wind_data = generate_verified_login
      if !wind_data.nil? && wind_data[:uni]
        uni = wind_data[:uni]
        wind_user = User.find_by_login(uni)
        if auto_register? and !wind_user
          if set_staff?(wind_data[:affils])
            User.set_staff!([uni])
          else
            User.unset_staff!([uni])
          end
          wind_user = User.find_by_login(uni)
        elsif wind_user and set_staff?(wind_data[:affils])
          User.set_staff!([uni])
        end
        self.attempted_record = search_for_record(find_by_wind_method, uni) 
        if !attempted_record
          if auto_register?
            self.attempted_record = klass.new(:login => uni, :wind_login => uni)
            self.attempted_record.reset_persistence_token
          else
            errors.add_to_base("Could not find UNI #{uni} in our database")
          end
        end
        role_names = wind_data[:affils].collect {|a| a }
        role_names.push("#{uni}:users.scv.cul.columbia.edu")
        if wind_user.cul_staff
          role_names.push("staff:scv.cul.columbia.edu")
        end
        role_names.uniq!
        roles = []
        role_names.each { |rs|
          role = Role.find_by_role_sym(rs)
          if !role
            role = Role.create(:role_sym=>rs)
          end
          roles.push(role)
        }
        # delete the existing role associations
        wind_user.roles.clear
        # add the new role associations
        wind_user.roles=roles 
        wind_user.save!
      else
        errors.add(:base,"WIND Ticket did not verify properly.")
      end  
    end
  end

  def generate_verified_login
    validate_path = "/validate?ticketid=#{wind_controller.params['ticketid']}"
    wind_validate = Net::HTTP.new("wind.columbia.edu",443)
    wind_validate.use_ssl = true
    wind_validate.start
    wind_resp = wind_validate.get(validate_path)
    wind_validate.finish
    #puts wind_resp.body
    authdoc = Nokogiri::XML(wind_resp.body)
    ns = {'wind'=>'http://www.columbia.edu/acis/rad/authmethods/wind'}
    _user = authdoc.xpath('//wind:authenticationSuccess/wind:user', ns)
    wind_data = nil
    if _user.length > 0
      wind_data = {}
      wind_data[:uni] =  _user[0].content
      wind_data[:affils] = authdoc.xpath('//wind:authenticationSuccess/wind:affiliations/wind:affil',ns).collect {|x| x.content}
    end
    wind_data
  end
end
