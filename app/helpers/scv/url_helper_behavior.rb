module Scv
  module UrlHelperBehavior
    def url_to_document(doc)
      url_for_opts = {:controller => :catalog, :action => :show}
      if doc.is_a? ActiveFedora::Base
        url_for_opts[:id] = (doc.pid)
      else
        url_for_opts[:id] = (doc[:id])
      end
      url_for url_for_opts
    end
    
    def onclick_to_document(document, formdata = {})
      data = {:counter => nil, :results_view => true}.merge(formdata)
      _opts = {:method=>:put,:data=>data,:class=>nil}
      _opts = _opts.stringify_keys
      convert_options_to_javascript_with_data!(_opts,url_to_document(document))
      _opts["onclick"]
    end

    # url_back_to_catalog(:label=>'Back to Search')
    # Create a url pointing back to the index screen, keeping the user's facet, query and paging choices intact by using session.
    def url_back_to_catalog(opts={:label=>'Back to Search'})
      query_params = session[:search] ? session[:search].dup : {}
      query_params.delete :counter
      query_params.delete :total
      return catalog_index_path(query_params)
    end

    def link_to_groups(groups)
      links = groups.collect {|g| link_to_mash(g,:label=>document_show_link_field)}
      links.join(', ').concat('.').html_safe
    end

    def link_to_mash(doc, opts={:label=>nil, :counter => nil, :results_view => true})
      opts[:label] = blacklight_config.index.show_link.to_sym unless opts[:label]
  # blacklight render_document_index_label will not handle a Symbol key appropriately for a Hash/Mash, and must have a proc
      if opts[:label].instance_of? Symbol
        old_label = opts[:label]
        opts[:label] = lambda { |doc, opts| Array(doc[old_label]).first}
      end
      link_to_document SolrDocument.new(doc), opts
    end

    def link_to_previous_document(doc)
      label="<i class=\"icon-chevron-left\"></i> Previous".html_safe
      return "<a href=\"\" class=\"prev\" rel=\"prev\">#{label}</a>" if doc == nil
      link_to label, doc, :class=>"prev", :rel=>'prev', :'data-counter' => session[:search][:counter].to_i - 1
    end

    def link_to_next_document(doc)
      label="Next <i class=\"icon-chevron-right\"></i>".html_safe
      return "<a href=\"\" class=\"next\" rel=\"next\">#{label}</a>" if doc == nil
      link_to label, doc, :class=>"next", :rel=>'next', :'data-counter' => session[:search][:counter].to_i + 1
    end

    def url_to_clio(document)
      if document.is_a? ActiveFedora::Base
        clio_id = document.datastreams['descMetadata'].term_values(:clio_ssm)
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
        link_to link_text + "<i class=\"icon-globe\"></i>".html_safe, clio_url, :target=>"_blank"
      else
        ""
      end
    end

    def link_to_object(object, opts={:label=>nil, :counter => nil, :results_view => true})
      label ||= lambda { |doc, opts| doc[blacklight_config[:index][:show_link].to_s]}
      label = render_document_index_label object, opts
      link_to label, {:controller => :catalog, :id=>object.pid}, :'data-counter' => opts[:counter]
    end
  end
end