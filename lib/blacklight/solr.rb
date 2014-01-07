module Blacklight::Solr
  
  autoload :Document, 'blacklight/solr/document'
  autoload :Facets, 'blacklight/solr/facets'
  autoload :FacetPaginator, 'blacklight/solr/facet_paginator'
  FacetPaginator.request_keys[:prefix] = :'facet.prefix'
  require 'blacklight/rsolr_facets'

end
