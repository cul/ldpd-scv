class Ability
  include CanCan::Ability 

  def initialize(user)
    @user = user || User.new # guest user, what about SSL/IP?
    Ability.config.select {|role,config| user.role? role }.each do |role, config|
      if config[:can]
        config[:can].each do |action, conditions|
          if conditions.blank?
            can action, :all
          else
            can action, Cul::DownloadProxy do |proxy|
              r = !!proxy
              if r
                unless conditions[:if].blank?
                  conditions[:if].each do |property, comparison|
                    comparison.each do |op, value|
                      p = proxy.send property
                      r &= (p && p.send(op, value))
                    end
                  end
                end
                unless conditions[:unless].blank?
                  conditions[:unless].each do |property, comparison|
                    comparison.each do |op, value|
                      r &= !(proxy.send property).send(op, value)
                    end
                  end
                end
              end
              r
            end
          end
        end
      end
    end
  end

  def self.config
    @role_proxy_config ||= begin
      root = (Rails.root.blank?) ? '.' : Rails.root
      path = File.join(root,'config','roles.yml')
      _opts = YAML.load_file(path)
      all_config = _opts.fetch("_all_environments", {})
      env_config = _opts.fetch(Rails.env, {})
      all_config.merge(env_config).recursive_symbolize_keys!
    end
  end

  config.each do |k,v|
    if v[:includes]
      v[:includes].each do |included|
        Role.role(k).includes(included.to_sym)
      end
    end
  end

end
