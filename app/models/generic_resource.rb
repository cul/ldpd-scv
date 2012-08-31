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
  
  IMAGE_EXT = {"image/bmp" => 'bmp', "image/gif" => 'gif', "image/jpeg" => 'jpg', "image/png" => 'png', "image/tiff" => 'tif', "image/x-windows-bmp" => 'bmp'}
  WIDTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_width))
  LENGTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_length))
  WIDTH_PREDICATE = ActiveFedora::RelsExtDatastream.short_predicate("http://www.w3.org/2003/12/exif/ns#imageWidth").to_s
  LENGTH_PREDICATE = ActiveFedora::RelsExtDatastream.short_predicate("http://www.w3.org/2003/12/exif/ns#imageLength").to_s
  EXTENT_PREDICATE = ActiveFedora::RelsExtDatastream.short_predicate("http://purl.org/dc/terms/extent").to_s
  FORMAT_OF_PREDICATE = ActiveFedora::RelsExtDatastream.short_predicate("http://purl.org/dc/terms/isFormatOf").to_s
  
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
  
  def linkable_resources
    # let's start with the known DSIDs from lindquist, then work our way back to parsing the solrized relsint
    results = []
    if (rels = rels_int.instance_variable_get :@solr_hash)
      # this was loaded from solr
      rels.each do |dsuri, props|
        if dsuri =~ /\/content$/ or not props[FORMAT_OF_PREDICATE].blank?
          dsid =  dsuri.split('/')[-1]
          res = datastream_as_resource(dsid, props)
          results << res
        end
      end
    else
      # read the graph
    end
    results
  end
  
  private
  def datastream_as_resource(dsid, props={})
    ds = datastreams[dsid]
    res = {}
    res[:pid] = self.pid
    res[:dsid] = dsid
    res[:mime_type] = ds.mimeType
    res[:content_models] = ["Datastream"]
    res[:file_size] = ds.dsSize.to_s
    if res[:file_size] == "0" and props[EXTENT_PREDICATE]
      res[:file_size] = (props[EXTENT_PREDICATE].first || "0")
    end
    res[:size] = (res[:file_size].to_i / 1024).to_s + " Kb"
    res[:width] = props[WIDTH_PREDICATE].first || "0"
    res[:height] = props[LENGTH_PREDICATE].first || "0"
    res[:dimensions] = "#{res[:width]} x #{res[:height]}"
    base_filename = pid.gsub(/\:/,"")
    res[:image_file_name] = base_filename + "." + dsid + "." + ds.mimeType.gsub(/^[^\/]+\//,"")
    #res[:show_path] = fedora_content_path("show", pid, dsid, img_filename)
    #res[:cache_path] = cache_path("show", pid, dsid, img_filename)
    #res[:download_path] = fedora_content_path("download", pid, dsid, img_filename)
    res
  end
        
end