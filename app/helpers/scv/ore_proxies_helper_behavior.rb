module Scv
  module OreProxiesHelperBehavior

    def hasModel_name
      @has_model ||= ActiveFedora::SolrService.solr_name('has_model', :symbol)
    end

    def publisher_name
      @has_model ||= ActiveFedora::SolrService.solr_name('publisher', :symbol)
    end

    def facets_for(query, args)
      raw = args.delete(:raw)
      args = args.merge(q:query, qt:'standard',facet:true,rows:0)
      result = ActiveFedora::SolrService.instance.conn.get('select', :params=>args)
      return result if raw
      result['facet_counts']['facet_fields']
    end
    def facet_to_hash(facet_values)
      facet_values ||= []
      hash = {}
      facet_values.each_with_index {|v,ix| hash[v] = facet_values[ix+1] if (ix % 2 == 0)}
      hash
    end
    def proxies(opts=params)
      proxy_in = opts[:id]
      proxy_uri = "info:fedora/#{proxy_in}"
      proxy_id = opts[:proxy_id]
      proxy_in_query = "proxyIn_ssi:#{RSolr.escape(proxy_uri)}"
      f = [proxy_in_query]
      if proxy_id
        f << "belongsToContainer_ssi:#{RSolr.escape(proxy_id)}"
      else
        f << "-belongsToContainer_ssi:*"
      end
      proxies = ActiveFedora::SolrService.query("*:*",{fq: f,rows:'999'})
      if proxies.detect {|p| p["type_ssim"] && p["type_ssim"].include?(RDF::NFO[:'#FileDataObject'])}
        query = "{!join from=proxyFor_ssi to=identifier_ssim}#{f.join(' ')}"
        files = ActiveFedora::SolrService.query(query,rows:'999')
        proxies.each do |proxy|
          file = files.detect {|f| f['identifier_ssim'].include?(proxy['proxyFor_ssi'])}
          if file
            rels_int = file.fetch('rels_int_profile_tesim',[]).first
            props = rels_int ? JSON.load(rels_int) : {}
            props = props["#{proxy_uri}/content"] || {}
            props['pid'] = file['id']
            props['extent'] ||= file['extent_ssim'] if file['extent_ssim']
            proxy.merge!(props)
          end
        end
      end
      if proxies.detect {|p| p["type_ssim"] && p["type_ssim"].include?(RDF::NFO[:'#Folder'])}
        query = "{!join from=id  to=belongsToContainer_ssi}#{f.join(' ')}"
        folder_counts = facets_for(query,:"facet.field" => "belongsToContainer_ssi",:"facet.limit" => '999')
        unless ( belongsToContainer = facet_to_hash(folder_counts["belongsToContainer_ssi"])).empty?
          proxies.each do |proxy|
            if proxy["type_ssim"].include?(RDF::NFO[:'#Folder'])
              proxy['extent'] ||= belongsToContainer[proxy['id']]
            end
          end
        end
      end
      proxies
    end

    def proxies_file_system(opts=params)
      nodes = proxies(opts)
      content_tag(:ul, nil, class: 'file-system') do
        children_content = nodes.reduce('') do |content, node|
          content << proxy_node(node)
        end
        children_content.html_safe
      end
    end

    def download_permitted?(dl_proxy, args={})
      return permitted_to? :fedora_content, dl_proxy, {:context => :download}
    end

    def proxy_to_download(node, args={})
      dl_proxy = Cul::Scv::DownloadProxy.new(args)
      dl_proxy.content_models = node[hasModel_name()]
      dl_proxy.mime_type = node['format']
      dl_proxy.publisher = node[publisher_name()]
      dl_proxy
    end

    def download_link(node, label)
      dl_proxy = proxy_to_download(node)
      if permitted_to?(:fedora_content, dl_proxy, {:context => :download} ) and node['pid']
        args = {uri: node['pid'], filename:node['label_ssi'], block: 'content'}
        args = dl_proxy.to_h.merge(args)
        href = uri_from_resource_parms(args, "download")
        content_tag(:a, label, href: href)
      else
        content_tag(:span, label)
      end
    end

    def proxy_node(node)
      label = node['extent'] ? "#{node['label_ssi']} (#{proxy_extent(node)})" : node['label_ssi']
      if node["type_ssim"].include? RDF::NFO[:'#FileDataObject']
        # file
        content_tag(:li,nil, class: ['fs-file',html_class_for_filename(node['label_ssi'])]) do
          c = download_link(node, label)
          if node['pid']
            c += content_tag(:a, 'Preview', href: '#', 'data-id'=>node['proxyFor_ssi'], class: 'preview') do 
              content_tag(:i,nil,class:'glyphicon glyphicon-info-sign')
            end
          end
          c
        end
      else
        # folder
        content_tag(:li, nil, class: 'fs-directory') do
          content_tag(:a, label, href: proxy_url(id: node['proxyIn_ssi'].sub('info:fedora/',''), proxy_id: node['id']))
        end
      end
    end

    def proxy_extent(node)
      extent = Array(node['extent']).first || '0'
      if node["type_ssim"].include? RDF::NFO[:'#FileDataObject']
        extent = extent.to_i
        pow = Math.log(extent,1024).floor
        pow = 3 if pow > 3
        pow = 0 if pow < 0
        unit = ['B','KiB','MiB','GiB'][pow]
        "#{extent.to_i/(1024**pow)} #{unit}"
      else
        "#{extent.to_i} items"
      end
    end
    def breadcrumbs(opts=params)
      proxy_id = opts[:proxy_id]
      id = opts[:id]
      links = []
      if proxy_id
        parts = proxy_id.split('/')
        links << content_tag(:span,nil, class: 'fs-directory') do
          content_tag(:a, 'All Content', href: catalog_url(id: id.sub('info:fedora/','')))
        end
        # the first three parts are proxied graph prefixes "info:fedora/PID/DSID/..."
        3.upto(parts.size - 2).each do |ix|
          f_id = parts[0..ix].join('/')
          f_label = parts[ix]
          links << content_tag(:span,nil, class: 'fs-directory') do
            content_tag(:a, f_label, href: proxy_url(id: id.sub('info:fedora/',''), proxy_id: URI.escape(f_id)))
          end
        end
        links << content_tag(:span,parts[-1], class: 'fs-directory')
      end
      links
    end
  end
end