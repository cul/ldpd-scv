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






    ##############################

    config[:unique_key] = :id
    config[:default_qt] = "search"


    # solr field values given special treatment in the show (single result) view
    config[:show] = {
      :html_title => "title_display",
      :heading => "title_display",
      :display_type => "format"
    }

    # solr fld values given special treatment in the index (search results) view
    config[:index] = {
      :show_link => "title_display",
      :num_per_page => 10,
      :record_display_type => "format"
    }

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    # TODO: Reorganize facet data structures supplied in config to make simpler
    # for human reading/writing, kind of like search_fields. Eg,
    # config[:facet] << {:field_name => "format", :label => "Format", :limit => 10}
    config[:facet] = {
      :field_names => (facet_fields = [
        "lib_project_facet",
        "lib_name_facet",
        "lib_date_facet",
        "lib_format_facet",
        "lib_collection_facet",
        "lib_repo_facet",
        "date_created_h",
        "pub_date",
        "subject_topic_facet",
        "language_facet",
        "lc_1letter_facet",
        "subject_geo_facet",
        "subject_era_facet"
      ]),
      :labels => {
        "lib_project_facet"              => "Projects",
        "lib_name_facet"            => "Names",
        "lib_date_facet"            => "Dates",
        "lib_format_facet"              => "Formats",
        "lib_collection_facet"              => "Collections",
        "lib_repo_facet"            => "Repositories",
        "date_created_h"              => "Date (Experimental)",
        "subject_topic_facet" => "Topics",
        "language_facet"      => "Languages",
        "lc_1letter_facet"    => "Call Numbers",
        "subject_era_facet"   => "Eras",
        "subject_geo_facet"   => "Regions"
      },
      # Setting a limit will trigger Blacklight's 'more' facet values link.
      # If left unset, then all facet values returned by solr will be displayed.
      # nil key can be used for a default limit applying to all facets otherwise
      # unspecified. 
      # limit value is the actual number of items you want _displayed_,
      # #solr_search_params will do the "add one" itself, if neccesary.
      :limits => {
        "lib_project_facet"    => 10,
        "lib_name_facet"       => 10,
        "lib_date_facet"       => 10,
        "lib_format_facet"     => 10,
        "lib_collection_facet" => 10,
        "lib_repo_facet"       => 10,
        "collection_h"         => 10,
        "date_created_h"       => 10,
        "subject_topic_facet"  => 10,
        "subject_era_facet"    => 10,
        "subject_geo_facet"    => 10
      },
      # sorts should be true/false prior to Solr 1.4, "count"/"index" after
      :sorts => {
        "lib_collection_facet" => "index",
        "lib_name_facet"       => "index",
        "lib_project_facet"    => "index",
        "lib_repo_facet"       => "index"
      },
      :hierarchy => {
        "date_created_h" => true,
        "collection_h" => true
      }
    }
    if !Rails.env.eql?"passenger_prod"
      config[:facet][:field_names].concat(["collection_h","format","descriptor"])
      config[:facet][:labels]["collection_h"] = "In Hierarchy"
      config[:facet][:labels]["format"] = "Routed As"
      config[:facet][:labels]["descriptor"] = "Metadata Type"
      config[:facet][:limits]["collection_h"] = 10
      config[:facet][:limits]["format"] = 10
      config[:facet][:limits]["descriptor"] = 10
    end

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config[:default_solr_params] ||= {}
    config[:default_solr_params][:"facet.field"] = facet_fields
    facet_fields.each { |ff|
      config[:default_solr_params][:"f.#{ff}.facet.sort"] = config[:facet][:sorts][ff] || "count"
    }


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    config[:index_fields] = {
      :field_names => [
        "title_display",
        "lib_name_facet",
        "lib_repo_facet",
        "lib_collection_facet",
        "title_vern_display",
        "author_display",
        "author_vern_display",
        "lib_format_facet",
        "format",
        "clio_s",
        "extent_t",
        "lib_project_facet",
        "language_facet",
        "published_display",
        "object_display",
        "lc_callnum_display",
        "index_type_label_s",
        "resource_json"
      ],
      :labels => {
        "title_display"           => "Title:",
        "title_vern_display"      => "Title:",
        "author_display"          => "Author:",
        "author_vern_display"     => "Author:",
        "lib_format_facet"                  => "Format:",
        "format"                  => "Routing:",
        "clio_s"                  => "CLIO Id:",
        "lib_collection_facet"  => "Collection:",
        "lib_project_facet"  => "Project:",
        "lib_name_facet"  => "Names:",
        "lib_repo_facet"  => "Repository:",
        "extent_t"  => "Extent:",
        "language_facet"          => "Language:",
        "published_display"       => "Published:",
        "object_display"          => "In Fedora:",
        "lc_callnum_display"      => "Call number:"
      }
    }

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