require "active-fedora"
class JP2ImageAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Fedora::UrlHelperBehavior
  include Cul::Scv::Hydra::Models::Common
  include Cul::Scv::Hydra::Models::Aggregator
  include Cul::Scv::Hydra::Models::LinkableResources

  has_datastream :name => "SOURCE", :type=>::ActiveFedora::Datastream, :mimeType=>"image/jp2", :controlGroup=>'E'

  alias :file_objects :resources

  def route_as
    "zoomingimage"
  end

  def index_type_label
    "PART"
  end

  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super
    source = self.datastreams["SOURCE"]
    source.profile
    if source.controlGroup == 'E'
      solr_doc["rft_id_ss"] = source.dsLocation
    else
      rc = ActiveFedora::RubydoraConnection.instance.connection
      url = rc.config["url"]
      uri = URI::parse(url)
      url = "#{uri.scheme}://#{uri.host}:#{uri.port}/fedora/objects/#{pid}/datastreams/SOURCE/content"
      solr_doc["rft_id_ss"] = url
    end
    solr_doc
  end
  
  def thumbnail_info
    url = fedora_method_url(pid,'ldpd:sdef.Image/getView?max=250')
    {:url => url, :mime => 'image/jpeg'}
  end
end
