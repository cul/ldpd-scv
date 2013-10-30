require "active-fedora"
require "active_fedora_finders"
class BagAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator
  alias :file_objects :resources

  def route_as
    "collection"
  end
  
  def thumbnail_info
    members = part_ids
    if members.length == 0
      return {:asset=>"crystal/file.png",:mime=>'image/png'}
    else
      member = ActiveFedora::Base.find(members[0], :cast=>true)
      if member.respond_to? :thumbnail_info
        return member.thumbnail_info
      end
    end
    return {:asset=>"crystal/file.png",:mime=>'image/png'}
  end
end