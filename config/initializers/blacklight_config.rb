require 'blacklight'
# You can configure Blacklight from here. 
#   
#   Blacklight.configure(:environment) do |config| end
#   
# :shared (or leave it blank) is used by all environments. 
# You can override a shared key by using that key in a particular
# environment's configuration.
# 
# If you have no configuration beyond :shared for an environment, you
# do not need to call configure() for that envirnoment.
# 
# For specific environments:
# 
#   Blacklight.configure(:test) {}
#   Blacklight.configure(:development) {}
#   Blacklight.configure(:production) {}
# 

module Scv
class BlacklightConfiguration
  def self.configure(config)

  #   Set up and register the default SolrDocument Marc extension
  #   SolrDocument.extension_parameters[:marc_source_field] = :marc_display
  #   SolrDocument.extension_parameters[:marc_format_type] = :marc21
  #   SolrDocument.use_extension( Blacklight::Solr::Document::Marc) do |document|
  #    document.key?( :marc_display  )
  #  end
    config.default_solr_params = {
          :qt => 'search',
          :defType          => "edismax",
          :facet            => true,
          :'facet.mincount' => 1,
          :rows         => 10,
          :'q.alt'          => "*:*",
          :qf               => [
                                'lib_project_facet^1',
                                'lib_name_facet^1',
                                'lib_date_facet^1',
                                'lib_format_facet^1',
                                'lib_collection_facet^1',
                                'lib_repo_facet^1',
                                'subject_topic_facet^1',
                                'language_facet^1',
                                'subject_geo_facet^1',
                                'subject_era_facet^1',
                                'format^1',
                                ]
        }





    ##############################

    config[:unique_key] = :id

    # solr field values given special treatment in the show (single result) view
    config.show.html_title = 'title_display'
    config.show.heading = 'title_display'
    config.show.display_type = :format

    # solr fld values given special treatment in the index (search results) view
    config.index.show_link = 'title_display'
    config.index.record_display_type = :format

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    # TODO: Reorganize facet data structures supplied in config to make simpler
    # for human reading/writing, kind of like search_fields. Eg,
    # config[:facet] << {:field_name => "format", :label => "Format", :limit => 10}
    config.add_facet_field "lib_project_facet", :label => "Projects", :limit => 10 #, :sort => "index"
    config.add_facet_field "lib_name_facet", :label => "Names", :limit => 10, :sort => "index"
    config.add_facet_field "lib_date_facet", :label => "Dates", :limit => 10, :sort => "count"
    config.add_facet_field "lib_format_facet", :label => "Formats", :limit => 10 #, :sort => "count"
    config.add_facet_field "lib_collection_facet", :label => "Collections" #, :limit => 10, :sort => "index"
    config.add_facet_field "lib_repo_facet", :label => "Repositories", :limit => 10 #, :sort => "index"
    config.add_facet_field "date_created_h", :label => "Date (Experimental)", :limit => 10, :sort => "count"
    config.add_facet_field "subject_topic_facet", :label => "Topics", :limit => 10, :sort => "count"
    config.add_facet_field "language_facet", :label => "Languages", :limit => 10, :sort => "count"
    config.add_facet_field "subject_geo_facet", :label => "Regions", :limit => 10, :sort => "count"
    config.add_facet_field "subject_era_facet", :label => "Eras", :limit => 10, :sort => "count"

    if !Rails.env.eql?"passenger_prod"
      config.add_facet_field "collection_h", :label => "In Hierarchy", :limit => 10
      config.add_facet_field "format", :label => "Routed As", :limit => 10
      config.add_facet_field "descriptor", :label => "Metadata Type", :limit => 10
    end

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    #config.default_solr_params[:'facet.field'] = config.facet_fields.keys

    config.add_index_field "title_display", :label => "Title:"
    config.add_index_field "title_vern_display", :label => "Title:"
    config.add_index_field "lib_name_facet", :label => "Names:"
    config.add_index_field "lib_repo_facet", :label => "Repository:"
    config.add_index_field "lib_collection_facet", :label => "Collection:"
    config.add_index_field "author_display", :label => "Author:"
    config.add_index_field "author_vern_display", :label => "Author:"
    config.add_index_field "lib_format_facet", :label => "Format:"
    config.add_index_field "format", :label => "Routing:"
    config.add_index_field "clio_s", :label => "CLIO Id:"
    config.add_index_field "extent_t", :label => "Extent:"
    config.add_index_field "lib_project_facet", :label => "Project:"
    config.add_index_field "language_facet", :label => "Language:"
    config.add_index_field "published_display", :label => "Published:"
    config.add_index_field "object_display", :label => "In Fedora:"
    config.add_index_field "index_type_label_s"
    config.add_index_field "resource_json"

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config[:show_fields] = {
      :field_names => [
        "title_display",
        "title_vern_display",
        "subtitle_display",
        "subtitle_vern_display",
        "author_display",
        "author_vern_display",
        "lib_format_display",
        "format",
        "lib_collection_display",
        "lib_repo_display",
        "url_fulltext_display",
        "url_suppl_display",
        "material_type_display",
        "language_facet",
        "published_display",
        "published_vern_display",
        "lc_callnum_display",
        "object_display",
        "isbn_t",
        "resource_json"
      ],
      :labels => {
        "title_display"           => "Title:",
        "title_vern_display"      => "Title:",
        "subtitle_display"        => "Subtitle:",
        "subtitle_vern_display"   => "Subtitle:",
        "author_display"          => "Author:",
        "author_vern_display"     => "Author:",
        "lib_format_display"                  => "Format:",
        "format"                  => "Routing:",
        "lib_collection_display"  => "Collection:",
        "lib_repo_display"  => "Repository:",
        "url_fulltext_display"    => "URL:",
        "url_suppl_display"       => "More Information:",
        "material_type_display"   => "Physical description:",
        "language_facet"          => "Language:",
        "published_display"       => "Published:",
        "published_vern_display"  => "Published:",
        "lc_callnum_display"      => "Call number:",
        "object_display"          => "In Fedora:",
        "isbn_t"                  => "ISBN:"
      }
    }

  # "fielded" search configuration. Used by pulldown among other places.
    config.add_search_field "all_fields", :label => 'All Fields'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    config.add_search_field "title", :qt => 'title_search',
     :solr_parameters => {
       :"spellcheck.dictionary" => "title"
      },
     :solr_local_parameters => {
       #  removing :qf => "$title_qf",
       #  removing :pf => "$title_pf"
      }
    config.add_search_field "name", :qt => 'name_search',
     :solr_parameters => {
       :"spellcheck.dictionary" => "name"
      },
     :solr_local_parameters => {
      }
    config.add_search_field "clio", :label => 'CLIO ID', :qt => 'clio_search',
     :solr_parameters => {
       :"spellcheck.dictionary" => "clio"
      },
     :solr_local_parameters => {
      }


    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field 'score desc, title_sort asc, date_created_dt desc', :label => 'relevance'
    config.add_sort_field 'date_created_dt desc, title_sort asc', :label => 'year'
    config.add_sort_field 'title_sort asc, date_created_dt desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config[:spell_max] = 5
  end
end
end