require 'securerandom'
class User < ActiveRecord::Base
# Connects this user object to Blacklights Bookmarks and Folders. 
  include Blacklight::User
  include Cul::Omniauth::Users
  has_and_belongs_to_many :roles
  before_create :set_personal_info_via_ldap

  scope :admins, -> {where(admin: true)}

  def to_s
    if first_name
      first_name.to_s + ' ' + last_name.to_s
    else
      login
    end
  end

  def set_personal_info_via_ldap
    if wind_login
      entry = Net::LDAP.new({:host => "ldap.columbia.edu", :port => 389}).search(:base => "o=Columbia University, c=US", :filter => Net::LDAP::Filter.eq("uid", wind_login)) || []
      entry = entry.first

      if entry
        _mail = entry[:mail].to_s
        if _mail.length > 6 and _mail.match(/^[\w.]+[@][\w.]+$/)
          self.email = _mail
        else
          self.email = wind_login + '@columbia.edu'
        end
        self.last_name = entry[:sn].to_s
        self.first_name = entry[:givenname].to_s
      end
    end

    return self
  end
  def password
    SecureRandom.hex[0...20]
  end
  def self.set_staff!(unis = [])
    unis.each do |uni|
      if (u = User.find_by_login(uni))
        u.update_attributes(:email => uni + "@columbia.edu", :cul_staff => true)
      else
        User.create!(:login => uni, :wind_login => uni, :email => uni + "@columbia.edu", :cul_staff => true, :password => SecureRandom.base64(8)) 
      end
    end
  end
  def self.unset_staff!(unis = [])
    unis.each do |uni|
      if (u = User.find_by_login(uni))
        u.update_attributes(:email => uni + "@columbia.edu", :cul_staff => false)
      else
        User.create!(:login => uni, :wind_login => uni, :email => uni + "@columbia.edu", :cul_staff => false, :password => SecureRandom.base64(8)) 
      end
    end
  end
  def role_symbols
    self.roles.collect {|r| r.to_sym}
  end
  def role? role_sym
    return true if role_sym.eql? :*
    role_symbols.detect {|sym| (sym.eql? role_sym.to_sym) || Role.role(sym).include?(role_sym)}
  end
end
