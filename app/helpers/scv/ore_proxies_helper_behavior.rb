module Scv
  module OreProxiesHelperBehavior
    include Cul::Hydra::OreProxiesHelperBehavior
#-- OVERRIDE FOR EXTENT --#
  def proxies(opts=params, &block)
    proxy_in = opts[:id]
    proxy_uri = "info:fedora/#{proxy_in}"
    proxy_id = opts[:proxy_id]
    proxy_in_query = "proxyIn_ssi:#{RSolr.solr_escape(proxy_uri)}"
    f = [proxy_in_query]
    if proxy_id
      f << "belongsToContainer_ssi:#{RSolr.solr_escape(proxy_id)}"
    else
      f << "-belongsToContainer_ssi:*"
    end
    rows = opts[:limit] || '999'
    proxies = ActiveFedora::SolrService.query("*:*",{fq: f,rows:rows})
    if proxies.detect {|p| p["type_ssim"] && p["type_ssim"].include?(RDF::NFO[:'#FileDataObject'])}
      query = "{!join from=proxyFor_ssi to=identifier_ssim}#{f.join(' ')}"
      files = ActiveFedora::SolrService.query(query,rows:'999')
      proxies.each do |proxy|
        file = files.detect {|f| f['identifier_ssim'].include?(proxy['proxyFor_ssi'])}
        if file
          rels_int = file.fetch('rels_int_profile_tesim',[]).first
          props = rels_int ? JSON.load(rels_int) : {}
          props = props["info:fedora/#{file['id']}/content"] || {}
          props['pid'] = file['id']
          props['extent'] ||= file['extent_ssim'].first if file['extent_ssim']
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
    if block_given?
      proxies.each &block
    else
      proxies
    end
  end
#-- END OVERRIDE --#
    def download_link(node, label, *classes)
      dl_proxy = proxy_to_download(node,{:context => :download})
      if can?(:download, dl_proxy, {:context => :download} ) and node['pid']
        args = {uri: node['pid'], filename:node['label_ssi'], block: 'content'}
        args = dl_proxy.to_h.merge(args)
        href = uri_from_resource_parms(args, "download")
        content_tag(:a, label, href: href, class: classes)
      else
        content_tag(:span, label, class: classes)
      end
    end

    def proxy_node(node)
      filesize = node['extent'] ? proxy_extent(node).html_safe : ''
      label = node['label_ssi']
      content_tag(:tr) do
        if node["type_ssim"].include? RDF::NFO[:'#FileDataObject']
          # file
          if node['pid']
            c = content_tag(:td,:"data-title"=>'Name') do
              d = download_link(node, label, ['fs-file',html_class_for_filename(node['label_ssi'])])
              d << content_tag(:a,title: 'Item permanent link',href:url_to_item(node['pid'],{return_to_filesystem:request.original_url})) do
                '&nbsp;'.html_safe << content_tag(:span,nil,class:"glyphicon glyphicon-info-sign")
              end
            end
            c << content_tag(:td,filesize, :"data-title" => 'Size', :"data-sort-value" => node['extent'].to_s)

            c << content_tag(:td,class:'fs-file') do
              node['format'] = MIME::Types.type_for(node['label_ssi']).collect {|x| x.content_type} unless node.fetch('format',[]).first
              if node['format'].first =~ /^image/
                content_tag(:a, href: '#', :'data-label' => label,:'data-uri'=>thumbnail_url({id: node['pid']},{region:'full'}),:"data-id"=>node['pid'], :"data-trigger" => 'focus',class: 'preview') do
                  image_tag(nil, class: 'lazy preview', :"data-original" => thumbnail_url({id: node['pid']},{type:'featured'}), width: 100, height: 100)
                end
              end
            end
          end
        else # folder
          c = content_tag(:td,:"data-title"=>'Name') do
            link_to(label, url_to_proxy({id: node['proxyIn_ssi'].sub('info:fedora/',''), proxy_id: node['id']}), class: 'fs-directory')
          end
          c << content_tag(:td,filesize,:"data-title"=>'Size',:"data-sort-value"=>node['extent'].to_s)
          c << content_tag(:td,nil)
        end
      end
    end
    def url_to_proxy(opts,decode=false)
      method = opts[:proxy_id] ? "#{controller_name}_proxy_url".to_sym : "#{controller_name}_url".to_sym
      if decode && opts[:proxy_id]
        opts = opts.merge(proxy_id:URI.unescape(opts[:proxy_id]))
      end
      send(method, opts.merge(label:nil))
    end
    def url_to_item(pid,additional_params={})
      method = "#{controller_name}_url".to_sym
      send method, {id: pid}.merge(additional_params)
    end
  end
end