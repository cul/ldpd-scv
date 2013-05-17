require "active-fedora"
require "active_fedora_finders"
class ContentAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::ActiveFedora::Relationships
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator
  alias :file_objects :resources

  def route_as
    "multipartitem"
  end
  
  def thumbnail_info
    members = resources(:response_format=>:id_array)
    if members.length > 1
      return {:asset=>"cul_scv_hydra/crystal/kmultiple.png",:mime=>'image/png'}
    elsif members.length == 0
      return {:asset=>"cul_scv_hydra/crystal/file.png",:mime=>'image/png'}
    else
      member = ActiveFedora::Base.find(members[0], :cast=>true)
      if member.respond_to? :thumbnail_info
        return member.thumbnail_info
      end
    end
    return {:asset=>"cul_scv_hydra/crystal/file.png",:mime=>'image/png'}
  end
end