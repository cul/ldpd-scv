require 'rsolr'
require 'blacklight'
require 'cul'
module ScvHelper
  include CatalogHelper
  include ModsHelper

  def http_client
    unless @http_client
      @http_client ||= HTTPClient.new
      @http_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      uname = Cul::Fedora.repository.config[:user]
      pwd = Cul::Fedora.repository.config[:password]
      @http_client.set_auth(nil, uname, pwd)
    end
    @http_client
  end

  def render_document_partial_with_locals(doc, action_name, locals={})
    format = document_partial_name(doc)
    locals = locals.merge({:document=>doc})
    begin
      render :partial=>"catalog/_#{action_name}_partials/#{format}", :locals=>locals
    rescue ActionView::MissingTemplate
      render :partial=>"catalog/_#{action_name}_partials/default", :locals=>locals
    end
  end

  def parse_image_resources!(document)
    if document[:parsed_resources]
      images = document[:parsed_resources]
    else
      if document[:resource_json]
        document[:parsed_resources] = document[:resource_json].collect {|rj| JSON.parse(rj)}
      else
        document[:parsed_resources] = Cul::Fedora::Objects::ImageObject.new(document,http_client).getmembers["results"]
      end
      images = document[:parsed_resources]
    end
    images
  end

  def image_thumbnail(document)
    images = parse_image_resources!(document)
    base_id = nil
    base_type = nil
    max_dim = 251
    images.each do |image|
      res = {}
      _w = image["imageWidth"].to_i
      _h = image["imageHeight"].to_i
      if _w < _h
        _max = _h
      else
        _max = _w
      end
      if _max < max_dim
        base_id = trim_fedora_uri_to_pid(image["member"])
        base_type = image["type"]
        max_dim = _max
      end
    end
    if base_id.nil?
      "http://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/ImageNA.svg/200px-ImageNA.svg.png"
    else
      base_filename = base_id.gsub(/\:/,"") + '.' +  base_type.gsub(/^[^\/]+\//,"")
      cache_path("show", base_id, "CONTENT", base_filename)
    end
  end

  def basic_resource(document)
    res = {}
    res[:mime_type] = document["dc_format_t"].first
    res[:content_models] = document["has_model_s"]
    res[:file_size] = document["extent_s"].first.to_i
    res[:size] = (document["extent_s"].first.to_i / 1024).to_s + " Kb"
    res
  end

  def image_resource(document)
    res = basic_resource(document)
    if document["image_width_s"]
      res[:dimensions] = document["image_width_s"].first + " x " + document["image_length_s"].first
      res[:width] = document["image_width_s"].first
      res[:height] = document["image_length_s"].first
    else
      res[:dimensions] = "? x ?"
      res[:width] = "0"
      res[:height] = "0"
    end
    base_id = document["id"]
    base_filename = base_id.gsub(/\:/,"")
    img_filename = base_filename + "." + document["dc_format_t"].first.gsub(/^[^\/]+\//,"")
    dc_filename = base_filename + "_dc.xml"
    res[:show_path] = fedora_content_path("show", base_id, "CONTENT", img_filename)
    res[:cache_path] = cache_path("show", base_id, "CONTENT", img_filename)
    res[:download_path] = fedora_content_path("download", base_id, "CONTENT", img_filename)
    res[:dc_path] = fedora_content_path('show_pretty', base_id, "DC", dc_filename)
    res
  end

  def audio_resource(document)
    res = basic_resource(document)
    base_id = document["id"]
    base_filename = base_id.gsub(/\:/,"")
    if res[:mime_type] =~ /wav/
      ext = 'wav'
    elsif res[:mime_type] =~ /mpeg/
      ext = 'mp3'
    else
      ext = 'bin'
    end
    filename = base_filename + "." + ext
    dc_filename = base_filename + "_dc.xml"
    res[:download_path] = fedora_content_path("download", base_id, "CONTENT", filename)
    res[:dc_path] = fedora_content_path('show_pretty', base_id, "DC", dc_filename)
    res
  end

  def get_resources(document)
    members = get_members(document)
    members = members.delete_if {|x| not x[:has_model_s].include? "info:fedora/ldpd:Resource" }
    return members if members.length == 0
    results = []
    format = document["format"]
    format = format.first if format.is_a? Array
    case format
    when "zoomingimage"
      results = members.collect {|doc| image_resource(doc)}
      base_id = base_id_for(document)
      url = Cul::Fedora::ResourceIndex.config[:riurl] + "/get/" + base_id + "/SOURCE"
      head_req = http_client.head(url)
      # raise head_req.inspect
      file_size = head_req.header["Content-Length"].first.to_i
      results << {:dimensions => "Original", :mime_type => "image/jp2", :show_path => fedora_content_path("show", base_id, "SOURCE", base_id + "_source.jp2"), :download_path => fedora_content_path("download", base_id , "SOURCE", base_id + "_source.jp2"), :content_models=>[]}  
    when "audio"
      results = members.collect {|doc| audio_resource(doc)}
    when "image"
        #images = parse_image_resources!(document)
      results = members.collect {|doc| image_resource(doc)}
    else
      raise "Unknown format #{format}"
    end
    logger.debug "returning #{results.length} resources of #{document["id"]}"
    return results
  end

  def base_id_for(doc)
    if doc.nil?
      doc
    else
      doc["id"].gsub(/(\#.+|\@.+)/, "")
    end
  end

  def doc_object_method(doc, method)
    Cul::Fedora::ResourceIndex.config[:riurl] + '/get/' + base_id_for(doc).to_s +  method.to_s
  end

  def doc_json_method(doc, method)
    res = JSON.parse(http_client.get_content(doc_object_method(doc,method)))
  end

  def get_aggregator_count(doc)
    # json = doc_json_method(doc, "/ldpd:sdef.Aggregator/getSize?format=json")
    json =  Cul::Fedora::Objects::ContentObject.new(doc,http_client).getsize
    if json
      json
    else
      return 0
    end
  end

  def get_fake_doc(pid,type)
    pid = pid.gsub(/^info\:fedora\/(.+)/,'\1')
    return {"id"=>pid,Blacklight.config[:show][:display_type]=>type}
  end

  def get_index_type_label(document)
    unless document["index_type_label_s"]
      logger.warn "did not expect #{document[:id]} to lack index_type_label_s"
      #docs = get_members(document)
      #if docs.length == 0
      #  label = "EMPTY"
      #elsif docs.length == 1
      #  label = "SINGLE PART"
      #else
      #  label = "MULTIPART"
      #end
      #update_doc(document[:id],{:index_type_label_s => label})
      #document[:index_type_label_s] = label
    end
    document["index_type_label_s"]
  end
  def update_doc(id, fields={})
      _solr = RSolr.connect :url => Blacklight.solr_config[:url]
      _doc = _solr.find({:qt => :document, :id => id})
      _doc = _doc.docs.first
      _doc.merge!(fields)
      add_attrs = {:allowDups=>false, :commitWithin=>10.0}
      _solr.add(_doc)
      _solr.commit
  end
  def get_first_member(document, imageOnly=True)
    docs = get_members(document)
    for doc in docs:
      logger.info "#{doc["id"]}  #{doc["format"]}"
      if imageOnly
        if doc["format"] ==  "image"
          return [doc,docs.length]
        end
      else
        return [doc,docs.length]
      end
    end
    return [false,docs.length]
  end

  def get_members(document, format=:solr)
    agg = GenericAggregator.load_instance_from_solr(document[:id],document)
    
    agg.parts(:response_format => format).hits.collect {|hit| SolrDocument.new(hit) }

    #idquery = document["id"]
    #if document["internal_h"]
    #  facet_prefix = document["internal_h"][0]
    #else
    #  resp, docs = get_independent_solr_response_for_field_values("id",document["id"])
    #  facet_prefix = docs[0]["internal_h"][0]
    #end
    #logger.info idquery
    #logger.info facet_prefix
    #search_field_def = Blacklight.search_field_def_for_key(:"internal_h")
    #_params = get_solr_params_for_field_values("internal_h",facet_prefix)
    #_params[:qt] = search_field_def[:qt] if search_field_def
    #_params[:per_page] = 100
    #resp = Blacklight.solr.find(_params)
    #docs = resp.docs
    #docs.delete_if {|doc| doc["id"].eql? idquery}
    #logger.info "got #{docs.length} docs"
    #docs
  end

  def get_solr_params_for_field_values(field, values, extra_controller_params={})
    value_str = "(\"" + values.to_a.join("\" OR \"") + "\")"
    solr_params = {
      :qt => "standard",   # need boolean for OR
      :q => "#{field}:#{value_str}",
      'fl' => "*",
      'facet' => 'false',
      'spellcheck' => 'false'
    }
    solr_params.merge(extra_controller_params)
  end
  def get_independent_solr_response_for_field_values(field, values, extra_controller_params={})
    _params = get_solr_params_for_field_values(field, values, extra_controller_params)
    if _params[:rows].is_a? Array
      _params[:rows] =  _params[:rows].first
    end
    logger.debug _params.inspect
    resp = Blacklight.solr.find(_params)
    [resp, resp.docs]
  end
  def get_groups(document)
    if document.is_a? ActiveFedora::Base
      document.containers(:response_format => :solr).hits.collect { |hit| SolrDocument.new(hit) }
    else
      get_groups_for_mash(document)
    end
  end
  def get_groups_for_mash(document)
    if document.is_a? SolrDocument
      groups = document.get(:cul_member_of_s)
    else
      groups = document["cul_member_of_s"]
    end
    groups ||= []
    groups = [groups] if groups.is_a? String 
    groups.collect! {|x| x.split(/\//,-1)}
    resp, docs = get_independent_solr_response_for_field_values("id",groups)
    docs.collect {|g| SolrDocument.new(g)}
    #search_params = get_solr_params_for_field_values("pid_s",groups)
    #resp = Blacklight.solr.find(search_params)
    #return resp.docs
  end

  def get_rows(member_list, row_length)
#    indexes = ((0...members.length).collect{|x| ((x % row_length)==0?x:nil}).compact
    indexes = []
    (0...member_list.length).collect {|x| if (x % row_length)==0 then  indexes.push x end}
    rows = []
    for index in indexes
      rows.push [index,index+1,index+2].collect {|x| member_list.at(x)?x:nil}
    end
    rows
  end
  def decorate_metadata_response(type, pid)
    res = {}
    res[:title] = type
    res[:id] = pid
    block = res[:title] == "DC" ? "DC" : "descMetadata"
    filename = res[:id].gsub(/\:/,"")
    filename += "_" + res[:title].downcase
    filename += ".xml"
       res[:show_url] = fedora_content_path(:show_pretty, res[:id], block, filename) + '?print_binary_octet=true'
    res[:download_url] = fedora_content_path(:download, res[:id], block, filename)
    res[:direct_link] = Cul::Fedora::ResourceIndex.config[:riurl] + "/get/" + res[:id] + "/" + block
    res[:type] = block == "DC"  ? "DublinCore" : "MODS"
    res
  end

  def get_metadata_list(doc, default=false)
    results = []
    if doc.nil?
      return results
    end
    if default
      idparts = doc[:id].split(/@/) unless doc[:id].nil?
      idparts ||= [""]
      md = idparts.last
      if not md.match(/^.*#DC$/)
        results << decorate_metadata_response("MODS" , base_id_for(doc))
      end
      results << decorate_metadata_response("DC" , base_id_for(doc))
      return results
    end

    json = [{"descMetadata" => base_id_for(doc)} , {"DC" => base_id_for(doc)}]

    json.each do  |meta_hash|
      meta_hash.each do |dsid, uri|
        res = decorate_metadata_response(dsid, trim_fedora_uri_to_pid(uri))
        begin
          res[:xml] = Nokogiri::XML(Cul::Fedora.repository.datastream_dissemination(:pid=>uri, :dsid=>dsid))
          root = res[:xml].root
          res[:type] = "MODS" if root.name == "mods" && root.attributes["schemaLocation"].value.include?("/mods/")
        rescue
          logger.error "Error fetching datastream #{uri}/#{dsid}"
        end

        extract_mods_details(res)
        results << res
      end
    end
    return results
  end

  def trim_fedora_uri_to_pid(uri)
    uri.gsub(/info\:fedora\//,"")
  end

  def resolve_fedora_uri(uri)
    Cul::Fedora::ResourceIndex.config[:riurl] + "/get" + uri.gsub(/info\:fedora/,"")
  end
  def link_to_clio(document,link_text="More information in CLIO")
     if document.is_a? ActiveFedora::Base
      clio_id = document.datastreams['descMetadata'].term_values(:clio)
      clio_id = clio_id.first unless clio_id.nil?
    else
      if document["clio_s"] and document["clio_s"].length > 0
        clio_id = document["clio_s"][0]
      end
    end

    if clio_id
      "<a href=\"http://clio.cul.columbia.edu:7018/vwebv/holdingsInfo?bibId=#{clio_id}\" target=\"_blank\">#{link_text}</a>"
    else
      ""
    end
  end

  def render_object_index_label doc, opts
    label = nil
    label ||= doc.get(opts[:label]) if opts[:label].instance_of? Symbol and doc.is_a? SolrDocument
    label ||= doc[opts[:label]] if opts[:label].instance_of? Symbol and doc.is_a? Mash
    label ||= opts[:label].call(doc, opts) if opts[:label].instance_of? Proc
    label ||= opts[:label] if opts[:label].is_a? String
    label ||= doc.pid
  end

  def link_to_object(object, opts={:label=>nil, :counter => nil, :results_view => true})
    label ||= Blacklight.config[:index][:show_link].to_sym
    label = render_object_index_label object, opts
    link_to label, {:controller => :catalog, :id=>object.pid}, :'data-counter' => opts[:counter]
  end

end
