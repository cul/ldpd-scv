require "active-fedora"
require "active_fedora_finders"
class BagAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::ActiveFedora::Relationships
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator
  include Cul::Scv::Solr4Queries
  alias :file_objects :resources

  def route_as
    "collection"
  end
end