module Scv
  module CatalogHelperBehavior

    include Scv::ModsHelperBehavior
    include Cul::Fedora::UrlHelperBehavior
    include Scv::UrlHelperBehavior
    include Scv::StructMetadataHelperBehavior
    include Scv::MembersHelperBehavior

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

    def rubydora
      @rubydora ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.configurator.fedora_config).connection
    end

    def get_resources(document)
      if (document.nil?)
        puts "document was nil?"
        return []
      end
      memoize = (document == @document)
      if memoize and @linkable_resources
        return @linkable_resources
      end
      linkable_resources = []
      obj = nil
      begin
        klass = document[:active_fedora_model_ssi].constantize
        obj = klass.load_instance_from_solr(document[:id],document)
      rescue Exception => e
        Rails.logger.warn(e.message)
        obj = ActiveFedora::base.find(document[:id], cast: true)
      end
      if (obj.respond_to? :linkable_resources)
        linkable_resources = obj.linkable_resources
      else
        linkable_resources = []
      end
      @linkable_resources = linkable_resources if memoize
      return linkable_resources
    end

    def uri_from_resource_parms(args = {}, dl_method="show")
      args = {:cache => false}.merge(args)
      if (args[:cache])
        cache_path(dl_method, args)
      else
        fedora_content_path(dl_method, args)
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
      fedora_method_url(base_id_for(doc).to_s, method.to_s)
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
      unless document["index_type_label_ssm"]
        logger.warn "did not expect #{document[:id]} to lack index_type_label_ssm"
      end
      document["index_type_label_ssm"]
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
        groups = document.get(:cul_member_of_ssim, :sep=>nil)
      else
        groups = document[:cul_member_of_ssim]
      end
      return [] if groups.blank?
      cache = Thread.current[:doc_cache]
      groups = [groups] if groups.is_a? String
      groups.collect! {|x| x.split(/\//,-1)[-1]}
      adds = groups - cache.keys
      unless adds.blank?
        resp, docs = get_independent_solr_response_for_field_values("id",adds)
        adds = docs.collect {|g| SolrDocument.new(g)}
        adds.each {|x| cache[x.get(:id)] = x unless x.nil? }
      end
      result = (groups.collect {|x| cache[x]}).compact
      result
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
      res[:direct_link] = fedora_ds_url(res[:id], block) + "/content"
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
        unless doc['descriptor_ssi'] =~ /dublin\score/i
          results << decorate_metadata_response("MODS" , base_id_for(doc))
        end
        results << decorate_metadata_response("DC" , base_id_for(doc))
        return results
      end

      json = []
      unless doc['descriptor_ssi'] =~ /dublin\score/i
        json << {"descMetadata" => base_id_for(doc)}
      end
        
      json << {"DC" => base_id_for(doc)}

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
      fedora_object_url(uri)
    end

    def zoomable?(document)
      zoomable = nil
      if document[:format_ssi] == 'zoomingimage' and document[:has_model_ssim].include? 'info:fedora/ldpd:JP2ImageAggregator'
        zoomable = ("info:fedora/#{document[:id]}/SOURCE")
      end
      rels_sym = [:rels_int_profile_tesim, :rels_int_profile_ssm].select {|sym| document[sym] and document[sym].first}.first
      if zoomable.nil? and rels_sym
        rels_int = JSON.parse(document[rels_sym].first)
        rels_int.each do |k,v|
          if v['foaf_zooming']
            zoomable = v['foaf_zooming'].first
          elsif v['format'] == ['image/jp2']
            zoomable = k
          end
        end
      end

      if zoomable.nil?
        resources = get_resources(document)
        resources.each do |resource|
          if resource[:mime_type] =~ /\/jp2$/
            if resource[:url]
              parts = resource[:url].split('/')
              zoomable = "info:fedora/#{parts[-4]}/#{parts[-2]}"
            elsif resource[:uri]
              zoomable = "info:fedora/#{resource[:uri]}/#{resource[:block]}"
            end                
          end
        end
      end
      return ('file:' + legacy_content_path(Cul::Fedora.ds_for_uri(zoomable))) if zoomable
      # else fall back to oldest behavior
      return document["rft_id_ss"]
    end

    def legacy_content_path(ds)
      unless ds.controlGroup == 'M'
        return ds.dsLocation
      end
      cd = ds.dsCreateDate
      tz = ActiveFedora.config.credentials[:time_zone]
      ds_root = ActiveFedora.config.credentials[:datastreams_root]
      tzi = ActiveSupport::TimeZone.find_tzinfo(tz)
      ld = tzi.utc_to_local(cd)
      month = (ld.month < 10) ? "0#{ld.month}" : ld.month.to_s
      day = (ld.day < 10) ? "0#{ld.day}" : ld.day.to_s
      hour = (ld.hour < 10) ? "0#{ld.hour}" : ld.hour.to_s
      min = (ld.min < 10) ? "0#{ld.min}" : ld.min.to_s
      return File.join(ds_root,"#{ld.year}/#{month}#{day}/#{hour}/#{min}", ds.dsLocation.sub(':','_'))
    end
  end
end