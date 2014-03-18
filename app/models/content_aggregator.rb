require "active-fedora"
require "active_fedora_finders"
class ContentAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator
  alias :file_objects :resources

  def route_as
    "multipartitem"
  end
  
  def thumbnail_info
    r = self.parts(:response_format => :solr)
    members = r.collect {|hit| SolrDocument.new(hit) } unless r.blank?
    if members.length == 0
      return {:asset=>"crystal/file.png",:mime=>'image/png'}
    else
      thumb = nil
      unless datastreams['structMetadata'].new?
        thumb = thumb_from_struct(members)
      else
        thumb =  thumb_from_members(members)
      end
    end
    return thumb || {:asset=>"crystal/file.png",:mime=>'image/png'}
  end

  private
  def thumb_from_struct(members)
    sm = datastreams['structMetadata']
    first = sm.divs_with_attribute(false,'ORDER','1').first
    if first
      members.each do |member|
        if member["identifier_ssim"].include? first["CONTENTIDS"]
          return thumb_from_solr_doc(member)
        end
      end
      return nil
    else
      return nil
    end
  end

  def thumb_from_members(members)
    sorted = members.sort do |a,b|
      c = a['title_si'] <=> b['title_si']
      if c == 0 && a['identifier_ssim']
        if b['identifier_ssim']
          a['identifier_ssim'].delete(a.id) unless a['identifier_ssim'].length == 1
          b['identifier_ssim'].delete(a.id) unless b['identifier_ssim'].length == 1
          a['identifier_ssim'][0] <=> b['identifier_ssim'][0]
        else
          -1
        end
      else
        c
      end
    end
    thumb_from_solr_doc(sorted[0])
  end

  def thumb_from_solr_doc(solr_doc)
    if solr_doc and (member =  ActiveFedora::Base.find(solr_doc.id, :cast=>true)).respond_to? :thumbnail_info
      return member.thumbnail_info
    else
      return nil
    end
  end
end
