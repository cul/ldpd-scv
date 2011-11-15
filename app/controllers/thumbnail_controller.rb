class ThumbnailController < ApplicationController
  # some thumbnail urls
  NO_THUMB = Rails.root + "/public/images/wikimedia/200px-ImageNA.svg.png"
  COLLECTION_THUMB = Rails.root + "/public/images/crystal/kmultiple.png"
  # some rel predicates
  FORMAT = "http://purl.org/dc/elements/1.1/format"
  MEMBER_OF = "http://purl.oclc.org/NET/CUL/memberOf"
  HAS_MODEL = "info:fedora/fedora-system:def/model#hasModel"
  IMAGE_WIDTH = "http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageWidth"
  IMAGE_LENGTH = "http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageLength"

  before_filter :require_staff
  caches_action :get, :expires_in => 7.days,
    :cache_path => proc { |c|
      c.params
    }
  def get
    pid = params[:id].split(/@/)[0]
    get_by_pid(pid)
  end
  def get_by_pid(pid)
    r_obj = Cul::Fedora::Objects::BaseObject.new({:pid_s => pid},http_client)
    tuples = r_obj.triples
    triples = {}
    tuples.each { |tuple|
      if triples.has_key?(tuple["predicate"])
        triples[tuple["predicate"]].push(tuple["object"])
      else
        triples[tuple["predicate"]]=[tuple["object"]]
      end
    }
    
    url = COLLECTION_THUMB
    if triples[HAS_MODEL].include?("info:fedora/ldpd:Resource")
      # do the triples indicate this is a thumb? fetch
      if thumb_triples?(triples)
        mime = triples[FORMAT].first
        url = {:url=>RI_CONFIG[:riurl] + "/get/" + pid + "/CONTENT", :mime=>mime}
      else
        if triples[MEMBER_OF].nil?
          url = {:url=>NO_THUMB,:mime=>'image/png'}
        else
          url = content_thumbnail(pid_from_uri(triples[MEMBER_OF].first))
        end
      end
      # else get thumb_url for first parent
    elsif triples[HAS_MODEL].include?("info:fedora/ldpd:ContentAggregator")
      url = content_thumbnail(pid)
    elsif triples[HAS_MODEL].include?("info:fedora/ldpd:JP2ImageAggregator")
      url = image_thumbnail(pid)
      if url[:url].eql?(NO_THUMB)
        url = jp2_thumbnail(pid)
      end
    elsif triples[HAS_MODEL].include?("info:fedora/ldpd:StaticImageAggregator")
      url = image_thumbnail(pid)
    else
      url = {:url=>COLLECTION_THUMB,:mime=>'image/png'}
    end
    filename = pid + '.' + url[:mime].split('/')[1].downcase
    h_cd = "filename=""#{CGI.escapeHTML(filename)}"""
    headers.delete "Cache-Control"
    headers["Content-Disposition"] = h_cd
    headers["Content-Type"] = url[:mime]
   
    if url[:url].eql?(NO_THUMB) || url[:url].eql?(COLLECTION_THUMB)
      render :status => 200, :text => File.read(url[:url])
      return
    else
      cl = http_client
      render :status => 200, :text => cl.get_content(url[:url])
      return
    end 
  end

  def thumb_triples?(triples)
    result = false
    if triples[IMAGE_WIDTH] && triples[IMAGE_LENGTH]
      width = triples[IMAGE_WIDTH].first.to_i
      length = triples[IMAGE_LENGTH].first.to_i
      result = 251 > width && 251 > length
    end
    return result
  end

  def content_thumbnail(pid)
    members = Cul::Fedora::Objects::ContentObject.new({:pid_s=>pid},http_client).getmembers["results"]
    if members.length > 1
      return {:url=>COLLECTION_THUMB,:mime=>'image/png'}
    elsif members.length == 0
      return {:url=>NO_THUMB,:mime=>'image/png'}
    else
      if members[0]["dctype"].downcase.eql?('image')
        pid = pid_from_uri(members[0]["member"])
        return image_thumbnail(pid)
      end
    end
    return {:url=>NO_THUMB,:mime=>'image/png'}
  end

  def image_thumbnail(pid)
    images = Cul::Fedora::Objects::ImageObject.new({:pid_s=>pid},http_client).getmembers["results"]
    base_id = nil
    base_type = nil
    max_dim = 251
    images.each do |image|
      _w = image["imageWidth"].to_i
      _h = image["imageHeight"].to_i
      if _w < _h
        _max = _h
      else
        _max = _w
      end
      puts "width: #{_w} height: #{_h} limit: #{max_dim} rejected: #{(max_dim >= _max).to_s}"
      if _max < max_dim
        base_id = pid_from_uri(image["member"])
        base_type = image["type"]
        max_dim = _max
      end
    end
    if base_id.nil?
      {:url=>NO_THUMB, :mime=>'image/png'}
    else
      {:url=>RI_CONFIG[:riurl] + "/get/" + base_id + "/CONTENT",:mime=>base_type}
    end
  end

  def jp2_thumbnail(pid)
    {:url => RI_CONFIG[:riurl] + '/objects/' + pid + '/methods/ldpd:sdef.Image/getView?max=250', :mime => 'image/jpeg'}
  end

  def pid_from_uri(uri)
    return uri.sub(/info:fedora\//,'')
  end
end
