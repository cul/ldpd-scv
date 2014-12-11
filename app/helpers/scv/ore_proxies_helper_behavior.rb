module Scv
  module OreProxiesHelperBehavior
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
        files = ActiveFedora::SolrService.query("{!join from=proxyFor_ssi to=identifier_ssim}#{f.join(' ')}",rows:'999')
        proxies.each do |proxy|
          file = files.detect {|f| f['identifier_ssim'].include?(proxy['proxyFor_ssi'])}
          if file
            rels_int = file.fetch('rels_int_profile_tesim',[]).first
            props = rels_int ? JSON.load(rels_int) : {}
            props = props["#{proxy_uri}/content"] || {}
            props['extent'] ||= file['extent_ssim'] if file['extent_ssim']
            proxy.merge!(props)
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
    def proxy_node(node)
      if node["type_ssim"].include? RDF::NFO[:'#FileDataObject']
        # file
        content_tag(:li,nil, class: ['fs-file',html_class_for_filename(node['label_ssi'])]) do
          label = node['extent'] ? "#{node['label_ssi']} (#{Array(node['extent']).first}b)" : node['label_ssi']
          content_tag(:a, label, href: '#', 'data-id'=>node['proxyFor_ssi'])
        end
      else
        # folder
        content_tag(:li, nil, class: 'fs-directory') do
          content_tag(:a, node['label_ssi'], href: proxy_url(id: node['proxyIn_ssi'].sub('info:fedora/',''), proxy_id: node['id']))
        end
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