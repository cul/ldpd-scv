require "active-fedora"
class StaticAudioAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::FinderMethods::RepositoryMethods
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator
  include Cul::Scv::Solr4Queries
  include Cul::Scv::LinkableResources
  alias :file_objects :resources

  def route_as
    "audio"
  end
  
  def index_type_label
    "PART"
  end
  
  def thumbnail_info
    return {:asset=>"crystal/sound.png",:mime=>'image/png'}
  end
end
