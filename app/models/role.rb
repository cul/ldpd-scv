class Role < ActiveRecord::Base
  has_and_belongs_to_many :users

  def to_sym
    self.role_sym.to_sym
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

  class RoleProxy
    attr_accessor :roles
    def initialize(name)
      @roles = []
    end
    def includes role
      roles << role unless roles.include? role
    end
    def include? role
      roles.include? role
    end
  end
  def self.role(name, &block)
    proxy = (proxies[name] ||= RoleProxy.new(name))
    if block_given?
      proxy.instance_eval &block
    end
    proxy
  end
  def self.proxies
    @proxies ||= {}
  end

  config.each do |k,v|
    if v[:includes]
      v[:includes].each do |included|
        Role.role(k).includes(included.to_sym)
      end
    end
  end
end
