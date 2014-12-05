namespace :cul do
  namespace :scv do
    namespace :users do

     desc "load the fedora configuration"
     task :configure => :environment do
       env = ENV['RAILS_ENV'] ? ENV['RAILS_ENV'] : 'development'
       yaml = YAML::load(File.open("config/fedora_ri.yml"))[env]
       ENV['RI_URL'] ||= yaml['riurl'] 
       ENV['RI_QUERY'] ||= yaml['riquery'] 
     end

     desc "add unis to SCV by setting cul_staff to TRUE"
     task :add_user => :configure do
       if ENV['UNIS']
         unis = ENV['UNIS'].split(/\s/)
         User.set_staff!(unis)
       end
     end

     desc "remove unis from SCV by setting cul_staff to FALSE"
     task :remove_user => :configure do
       if ENV['UNIS']
         unis = ENV['UNIS'].split(/\s/)
         User.unset_staff!(unis)
       end
     end

     desc "remove unis from SCV by deleting the user record"
     task :delete_user => :configure do
       if ENV['UNIS']
         unis = ENV['UNIS'].split(/\s/)
         unis.each { |uni|
           u = User.find_by_login(uni)
           u.delete
         }
       end
     end
    end
  end
end