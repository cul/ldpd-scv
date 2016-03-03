require 'nokogiri'
class GeoNetwork

  DSSC_ITEM_BASE = "http://sedac.ciesin.columbia.edu/geonetwork/srv/en/xml.metadata.get"

  NS = {geonet:"http://www.fao.org/geonetwork"}

  IMAGE_BASE_PATH = '/ifs/cul/dssc/source_data/PublicDomainScannedMaps'

  include GeoNetworkHelpers

  def self.find(id)
    Relation.new(id: id).first
  end

  def self.find_by(attrs)
    Relation.new(attrs)
  end

  def initialize(args={})
    if args[:id]
      @id = args[:id]
    end
    if (args[:response])
      res = args[:response]
      @ng_xml = Nokogiri::XML(res.body)
      @id = @ng_xml.xpath('//geonet:info/id', NS).each {|x| x.text}
    end
    if args[:xml]
      @ng_xml = Nokogiri::XML(args[:xml])
      @id = @ng_xml.xpath('//geonet:info/id', NS).each {|x| x.text}
    end
  end

  def css(query)
    ng_xml.css(query)
  end

  def ng_xml
    @ng_xml ||= begin
        uri = URI(DSSC_ITEM_BASE)
        data = "<request><id>#{@id}</id></request>"
        res = post(uri, data)
        ng_xml = Nokogiri::XML(res.body)
        @id = ng_xml.xpath('//geonet:info/id', NS).each {|x| x.text}
        ng_xml
    end
  end

  def uuid
    @uuid ||= ng_xml.xpath('//geonet:info/uuid',NS).first.text
  end

  def fedora_id
    @fedora_id ||= "dssc.#{uuid}"
  end

  def fedora
    ContentAggregator.search_repo(identifier: fedora_id).first
  end

  def img_basename
    File.basename(ng_xml.css('citation citeinfo onlink').first.text)
  end

  def tif_path
    File.join(IMAGE_BASE_PATH,img_basename.sub(/\.zip$/,'.tif'))
  end

  def tif_dsLocation
    File.join(IMAGE_BASE_PATH,URI.encode(img_basename.sub(/\.zip$/,'.tif')))
  end

  def tif_id
    File.join('apt://columbia.edu/dssc.maps/data/',img_basename.sub(/\.zip$/,'.tif'))
  end

  def jp2_path
    File.join(IMAGE_BASE_PATH,img_basename.sub(/\.zip$/,'.jp2'))
  end

  class Relation
    DSSC_SEARCH_BASE = "http://sedac.ciesin.columbia.edu/geonetwork/srv/en/xml.search"
    include GeoNetworkHelpers
    def initialize(attrs)
      keys = attrs.collect {|k,v| "<#{k}>#{v}</#{k}>" }
      @data = "<request>#{keys.join('')}</request>"
    end
    def load
      @results ||= begin
        uri = URI(DSSC_SEARCH_BASE)
        res = post(uri, @data)
        xml = res.body
        ng_xml = Nokogiri::XML(xml)
        @ids = ng_xml.css('response metadata id').collect {|n| n.text}
        @ids.collect {|id| GeoNetwork.new(id: id)}
      end
    end
    def first
      load.first
    end
  end
end