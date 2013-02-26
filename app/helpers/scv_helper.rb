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

  def get_resources(document)
    klass = ActiveFedora::SolrService.class_from_solr_document(document)
    obj = klass.load_instance_from_solr(document[:id],document)
    if (obj.respond_to? :linkable_resources)
      return obj.linkable_resources
    else
      return []
    end
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
  def get_first_member(document, imageOnly=true)
    docs = get_members(document)
    docs.each do |doc|
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
    klass = false
    document[:has_model_s].each do |model|
      klass ||= ActiveFedora::Model.from_class_uri(model)
    end
    klass ||= GenericAggregator
    if klass.include? Cul::Scv::Hydra::ActiveFedora::Model::Aggregator
      agg = klass.load_instance_from_solr(document[:id],document)
      r = agg.parts(:response_format => format)
      return [] if r.blank?
      return r["response"]["docs"].collect {|hit|
        SolrDocument.new(hit)
      }
    end
    return []
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

  def url_to_clio(document)
    if document.is_a? ActiveFedora::Base
      clio_id = document.datastreams['descMetadata'].term_values(:clio)
      clio_id = clio_id.first unless clio_id.nil?
    else
      if document["clio_s"] and document["clio_s"].length > 0
        clio_id = document["clio_s"][0]
      end
    end
    clio_id ? "http://clio.cul.columbia.edu:7018/vwebv/holdingsInfo?bibId=#{clio_id}" : false
  end
     

  def link_to_clio(document,link_text="More information in CLIO")
    clio_url = url_to_clio(document)
    if clio_url
      link_to link_text + image_tag("", :class=>"icon-globe", :style=>"border:none;"), clio_url, :class=>"btn", :target=>"_blank"
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
    label ||= blacklight_config[:index][:show_link].to_sym
    label = render_object_index_label object, opts
    link_to label, {:controller => :catalog, :id=>object.pid}, :'data-counter' => opts[:counter]
  end

end
