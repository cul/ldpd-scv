require 'kaminari'
module Scv
  module FacetsHelperBehavior
    include Blacklight::FacetsHelperBehavior
    # following kaminari link helpers, add facet range parameters
    def link_to_facet_prefix(scope, name, options ={}, &block)
      params = options.delete(:params) || {}
      param_name = options.delete(:param_name) || Kaminari.config.param_name
      range_start = options.delete(:'facet.prefix') || ''
      params = scope.params_for_resort_url('index',params).merge({:'facet.prefix' => range_start})
      link_to_unless scope.items.size < scope.limit,
       name,
       params.merge(param_name => (scope.current_page - 1)),
       options.reverse_merge(:rel => 'previous') do
        block.call if block
      end
    end
    def active_prefix?(prefix=nil)
      if (prefix.nil? or prefix == '') and (params['facet.prefix'].nil? or params['facet.prefix'] == '')
        true
      else
        params[:'facet.prefix'] == prefix
      end
    end
    def any_facet_in_params? field
      params[:f] and params[:f][field] and params[:f][field].length > 0
    end
    def should_render_facet? display_facet
      facet_config = facet_configuration_for_field(display_facet.name)
      if facet_config[:only]
        any_facet_in_params?( facet_config[:only] ) and super
      else
        super
      end
    end

    # OVERRIDES
    # Standard display of a SELECTED facet value, no link, special span
    # with class, and 'remove' button.
    def render_selected_facet_value(facet_solr_field, item)
      #Updated class for Bootstrap Blacklight
      deps = []
      (params[:f] || {}).each do |f,i|
        facet_config = facet_configuration_for_field(f)
        if facet_config[:only] and facet_config[:only] == facet_solr_field
          deps << facet_config[:field]
        end
      end

      remove_params = remove_facet_params(facet_solr_field, item, params)
      deps.each {|f| remove_params[:f].delete(f)}
      content_tag(:span, render_facet_value(facet_solr_field, item, :suppress_link => true), :class => "selected") +
        link_to(content_tag(:i, '', :class => "icon-remove") + content_tag(:span, '[remove]', :class => 'hide-text'), remove_params, :class=>"remove")
    end

  end
end