require 'cul/fedora/object'
module Cul
module Fedora
module ResourceIndex
  def self.ri_file
    File.join(Rails.root.to_s, 'config', 'fedora_ri.yml')
  end
  def self.config
    @ri_config ||= begin
      raise "You are missing a solr configuration file: #{ri_file}." unless File.exists?(ri_file)
      ri_config = YAML::load(File.open(ri_file))
      raise "The #{::Rails.env} environment settings were not found in the fedora_ri.yml config" unless ri_config[::Rails.env]
      ri_config[::Rails.env].symbolize_keys
    end
  end
end
end
end
