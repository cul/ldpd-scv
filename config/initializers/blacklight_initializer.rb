require 'blacklight'
require 'blacklight/solr'
require 'blacklight/solr/facet_paginator'
#require 'blacklight/solr/document'
#require 'blacklight/solr/request'
# A secret token used to encrypt user_id's in the Bookmarks#export callback URL
# functionality, for example in Refworks export of Bookmarks. In Rails 4, Blacklight
# will use the application's secret key base instead.
#
#TODO: yank this key when BL actually uses it?
if Blacklight.respond_to? :secret_key
  Blacklight.secret_key = '6bfc9ab5786c01e0bb2c82400122cf35af9859b23a733365d8bd05b8aa9ccc7dd0a23cde30fd99a4455c56aae1301ff9c8205344ffd022a0ee90adb785edfe15'
end
Blacklight::Solr::FacetPaginator.request_keys[:prefix] = :'facet.prefix'
