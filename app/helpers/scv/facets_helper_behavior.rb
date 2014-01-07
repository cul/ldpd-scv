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
  end
end