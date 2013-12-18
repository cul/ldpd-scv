module Cul
	module Scv
    module FacetExtras
      extend ActiveSupport::Concern

      included do
        self.solr_search_params_logic += [:add_facet_prefix_param]
        
      end
      
      def add_facet_prefix_param(solr_params = {}, user_params = params || {})
        if user_params.has_key? 'facet.prefix'
          solr_params['facet.prefix'] = user_params['facet.prefix']
        else
          solr_params.delete 'facet.prefix'
        end
        puts 'RABBLE RABBLE RABBLE'
      end
    end
  end
end
