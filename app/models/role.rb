class Role < ActiveRecord::Base
  has_and_belongs_to_many :users

  def to_sym
    self.role_sym.to_sym
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
end
