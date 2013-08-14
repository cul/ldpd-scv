require "active-fedora"
class StaticImageAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::ActiveFedora::Relationships
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator
  include Cul::Scv::LinkableResources
  alias :file_objects :resources
  
  CUL_WIDTH = ActiveFedora::RelsExtDatastream.short_predicate("http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageWidth")
  CUL_LENGTH = ActiveFedora::RelsExtDatastream.short_predicate("http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageLength")

  def route_as
    "image"
  end

  def index_type_label
    "PART"
  end
  
  def thumbnail_info
    candidate = nil
    max_dim = 0
    linkable_resources().each do |resource|
      width = resource[:width].to_s.to_i
      length = resource[:length].to_s.to_i
      max = (width > length) ? width : length
      if max > max_dim and max <= 251
        candidate = resource
        max_dim = max
      end
    end
    if candidate.nil?
      return {:asset=>"cul_scv_hydra/crystal/file_broken.png",:mime=>'image/png'}
    else
      return {:url=>"#{ActiveFedora.fedora_config.credentials[:url]}/objects/#{candidate[:pid]}/datastreams/CONTENT/content",:mime=>candidate[:mime_type]}
    end
  end
end
