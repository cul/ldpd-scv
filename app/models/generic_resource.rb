require "cul_image_props"
require "mime/types"
require "uri"
require "open-uri"
require "tempfile"
class GenericResource < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::ActiveFedora::Relationships
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include ::ActiveFedora::RelsInt
  alias :file_objects :resources
  
  IMAGE_EXT = {"image/bmp" => 'bmp', "image/gif" => 'gif', "imag/jpeg" => 'jpg', "image/png" => 'png', "image/tiff" => 'tif', "image/x-windows-bmp" => 'bmp'}
  WIDTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_width))
  LENGTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_length))
  
  has_datastream :name => "content", :type=>::ActiveFedora::Datastream, :versionable => true
  
  def assert_content_model
    super
    add_relationship(:rdf_type, Cul::Scv::Hydra::ActiveFedora::RESOURCE_TYPE.to_s)
  end

  def route_as
    "resource"
  end

  def index_type_label
    "FILE RESOURCE"
  end

  def to_solr(solr_doc = Hash.new, opts={})
    super
    unless solr_doc["extent_s"] || self.datastreams["content"].nil?
      solr_doc["extent_s"] = [self.datastreams["content"].size]
    end
    solr_doc
  end
  
  def thumbnail_info
    thumb = rels_int.relationships(datastreams['content'],:foaf_thumbnail).first
    if thumb
      t_dsid = thumb.object.to_s.split('/')[-1]
      return {:url=>"#{ActiveFedora.fedora_config.credentials[:url]}/objects/#{pid}/datastreams/#{t_dsid}/content",:mime=>datastreams[t_dsid].mimeType}
    else
      return {:asset=>"cul_scv_hydra/crystal/file.png",:mime=>'image/png'}
    end
  end
        
end