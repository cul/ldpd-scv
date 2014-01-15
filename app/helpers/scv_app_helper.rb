# coding: utf-8
module ScvAppHelper
  include ApplicationHelper
  def application_name
    "Columbia University Libraries Staff Collection Viewer Prototype"
  end
  # RSolr presumes one suggested word, this is a temporary fix
  def get_suggestions(spellcheck)
    words = []
    return words if spellcheck.nil?
    suggestions = spellcheck[:suggestions]
    i_stop = suggestions.index("correctlySpelled")
    0.step(i_stop - 1, 2).each do |i|
      term = suggestions[i]
      term_info = suggestions[i+1]
      origFreq = term_info['origFreq']
  # termInfo['suggestion'] is an array of hashes with 'word' and 'freq' keys
      term_info['suggestion'].each do |suggestion|
        if suggestion['freq'] > origFreq
          words << suggestion['word']
        end
      end
    end
    words
  end
  #
  # facet param helpers ->
  #

  # Standard display of a SELECTED facet value, no link, special span
  # with class, and 'remove' button.
  def render_selected_facet_value(facet_solr_field, item, removeable=false)
    result = super(facet_solr_field, item)
    if removeable
      result = result + ' [' + link_to("remove", remove_facet_params(facet_solr_field, item.value, params), :class=>"remove") + ']'
    end
    result.html_safe
  end

# Return a normalized partial name that can be used to contruct view partial path
  def object_partial_name(object)
    # .to_s is necessary otherwise the default return value is not always a string
    # using "_" as sep. to more closely follow the views file naming conventions
    # parameterize uses "-" as the default sep. which throws errors
    display_type = object.class.name

    return 'default' unless display_type
    display_type = display_type.join(" ") if display_type.respond_to?(:join)

    "#{display_type.gsub("-"," ")}".parameterize("_").to_s
  end

  # given a doc and action_name, this method attempts to render a partial template
  # based on the value of doc[:format]
  # if this value is blank (nil/empty) the "default" is used
  # if the partial is not found, the "default" partial is rendered instead
  def render_object_partial(object, action_name, locals = {})
    format = object_partial_name(object)
    locals = locals.merge({:object=>object})
    begin
      render :partial=>"catalog/_#{action_name}_partials/#{format}", :locals=>locals
    rescue ActionView::MissingTemplate
      render :partial=>"catalog/_#{action_name}_partials/default", :locals=>locals
    end

  end

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
end
