root = (Rails.root.blank?) ? '.' : Rails.root
ri_config_file = "#{root.to_s}/config/fedora_ri.yml"
creds_config_file = "#{root.to_s}/config/fedora_credentials.yml"
solr_config_file = "#{root.to_s}/config/solr.yml"
fedora_config_file = "#{root.to_s}/config/fedora.yml"
roles_config_file = "#{root.to_s}/config/roles.yml"

if File.exists?(ri_config_file)
  raw_config = File.read(ri_config_file)
  loaded_config = YAML.load(raw_config)
  all_config = loaded_config["_all_environments"] || {}
  env_config = loaded_config[Rails.env] || {}
  RI_CONFIG = all_config.merge(env_config).recursive_symbolize_keys!
end
if File.exists?(creds_config_file)
  raw_config = File.read(creds_config_file)
  loaded_config = YAML.load(raw_config)
  all_config = loaded_config["_all_environments"] || {}
  env_config = loaded_config[Rails.env] || {}
  FEDORA_CREDENTIALS_CONFIG = all_config.merge(env_config).recursive_symbolize_keys!
end
if File.exists?(solr_config_file)
  raw_config = File.read(solr_config_file)
  loaded_config = YAML.load(raw_config)
  all_config = loaded_config["_all_environments"] || {}
  env_config = loaded_config[Rails.env] || {}
  SOLR_CONFIG = all_config.merge(env_config).recursive_symbolize_keys!
end
if File.exists?(roles_config_file)
  raw_config = File.read(roles_config_file)
  loaded_config = YAML.load(raw_config)
  all_config = loaded_config["_all_environments"] || {}
  env_config = loaded_config[Rails.env] || {}
  ROLES_CONFIG = all_config.merge(env_config).recursive_symbolize_keys!
else
  raise "NO FILE AT #{roles_config_file}"
end
