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

module Cul::Scv::BlacklightConfiguration
  extend ActiveSupport::Concern
  module ClassMethods
  def dependent_facet(controller, config, display_facet)
    config[:only] and facet_in_params?(config[:only])
  end

  def configure_common(config)
  #   Set up and register the default SolrDocument Marc extension
  #   SolrDocument.extension_parameters[:marc_source_field] = :marc_display
  #   SolrDocument.extension_parameters[:marc_format_type] = :marc21
  #   SolrDocument.use_extension( Blacklight::Solr::Document::Marc) do |document|
  #    document.key?( :marc_display  )
  #  end
    config.default_solr_params = {
          :qt => 'search',
          :defType          => "dismax",
          :facet            => true,
          :'facet.mincount' => 1,
          :'facet.pivot.mincount' => 0,
          :rows         => 10,
          :'q.alt'          => "*:*"
        }





    ##############################

    config[:unique_key] = :id

    # solr field values given special treatment in the show (single result) view
    config.show.html_title = 'title_display_ssm'
    config.show.heading = 'title_display_ssm'
    config.show.display_type_field = :format_ssi

    # solr field values given special treatment in the index (search results) view
    config.index.show_link = 'title_display_ssm'
    config.index.display_type_field = :format_ssi
  end

  def configure_scv_facets(config)
    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_project_short', :symbol), :label => "Projects", :limit => 10, :sort => "index"
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_name', :facetable), { 
      :label => "Names", :limit => 10, :sort => "index"}
    config.add_facet_field "lib_recipient_sim", :label => "RCP", :limit => 10, :sort => "index", :only=>"lib_name_sim"
    config.add_facet_field "lib_date_dtsi", :label => "Dates", :limit => 10, :sort => "index"
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_format', :facetable), :label => "Formats", :limit => 10, :sort => "index"
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_collection', :facetable), :label => "Collections", :limit => 10, :sort => "index"
    config.add_facet_field "lib_shelf_sim", {
      :label => "Sublocation",
      :limit => 10,
      :sort => "index",
      :only => "lib_collection_sim"
    }
## field cannot be the nameof another facet!
#    config.add_facet_field "collection_pivot", {
#      label: "Collections (Pivot)",
#      pivot: ["lib_collection_sim", "lib_shelf_sim"],
#      sort: "index",
#      show: true
#    }
    config.add_facet_field ActiveFedora::SolrService.solr_name('lib_repo_short', :symbol), :label => "Repositories", :limit => 10, :sort => "index"
    config.add_facet_field "subject_topic_sim", :label => "Topics", :limit => 10, :sort => "index"
    config.add_facet_field ActiveFedora::SolrService.solr_name('language_language_term_text', :symbol), :label => "Languages", :limit => 10, :sort => "index"
    config.add_facet_field "subject_geo_sim", :label => "Regions", :limit => 10, :sort => "index"
    config.add_facet_field "subject_era_sim", :label => "Eras", :limit => 10, :sort => "index"

    if !Rails.env.eql?"passenger_prod"
      config.add_facet_field "format_ssi", :label => "Routed As", :limit => 10
      config.add_facet_field "descriptor_ssi", :label => "Metadata Type", :limit => 10
    end
  end

  def configure_seminars_facets(config)
    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field ActiveFedora::SolrService.solr_name('primary_name', :facetable), { 
      :label => "Seminar Numbers", :limit => 10, :sort => "index"}
    config.add_facet_field "subject_topic_sim", :label => "Seminar Titles", :limit => 10, :sort => "index"
    config.add_facet_field ActiveFedora::SolrService.solr_name('physical_description_form_local', :facetable), :label => "Document Types", :limit => 10, :sort => "index"
    config.add_facet_field ActiveFedora::SolrService.solr_name('language_language_term_text', :symbol), :label => "Languages", :limit => 10, :sort => "index"
    config.add_facet_field "lib_date_dtsi", :label => "Dates", :limit => 10, :sort => "index"
    config.add_facet_field ActiveFedora::SolrService.solr_name('physical_description_form_aat', :facetable), :label => "Library Formats", :limit => 10, :sort => "index"

  end

  def configure_for_scv(config)

    configure_common(config)
    configure_scv_facets(config)
    config.add_facet_fields_to_solr_request!

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    #config.default_solr_params[:'facet.field'] = config.facet_fields.keys

    config.add_index_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label => "Title:"
    config.add_index_field "title_vern_ssm", :label => "Title:"
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_name', :displayable, type: :string), :label => "Names:"
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_repo_long', :symbol, type: :string), :label => "Repository:"
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_collection', :displayable), :label => "Collection:"
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_date_textual', :displayable, type: :string), :label => 'Date:'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_format', :displayable), :label => "Format:"
    config.add_index_field "format_ssim", :label => "Routing:"
    config.add_index_field ActiveFedora::SolrService.solr_name('clio', :displayable), :label => "CLIO Id:"
    config.add_index_field "extent_ssm", :label => "Extent:"
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_project_full', :symbol), :label => "Project:"
    config.add_index_field "published_ssm", :label => "Published:"
    config.add_index_field "object_ssm", :label => "In Fedora:"
    config.add_index_field "cul_member_of_ssim"
    config.add_index_field "index_type_label_ssi"
    config.add_index_field "resource_json"

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label=>"Title:"
    config.add_show_field "title_vern_ssm", :label=>"Title:"
    config.add_show_field "subtitle_ssm", :label=>"Subtitle:"
    config.add_show_field "subtitle_vern_ssm", :label=>"Subtitle:"
    config.add_show_field ActiveFedora::SolrService.solr_name('identifier', :symbol), :label => 'Identifier', :separator => '; '
    config.add_show_field "author_ssm", :label=>"Author:"
    config.add_show_field "author_vern_ssm", :label=>"Author:"
    config.add_show_field "lib_format_ssm", :label=>"Format:"
    config.add_show_field "format_ssim", :label=>"Routing:"
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_collection', :displayable), :label=>"Collection:"
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_repo_full', :symbol, type: :string), :label=>"Repository:"
    config.add_show_field "url_fulltext_ssm", :label=>"URL:"
    config.add_show_field "url_suppl_ssm", :label=>"More Information:"
    config.add_show_field "material_type_ssm", :label=>"Physical Description:"
    config.add_show_field "published_ssm", :label=> "Published:"
    config.add_show_field "published_vern_ssm", :label=> "Published:"
    config.add_show_field "lc_callnum_ssm", :label=> "Call number:"
    config.add_show_field "object_ssm", :label=> "In Fedora:"
    config.add_show_field "isbn_ssim", :label=> "ISBN:"

  # "fielded" search configuration. Used by pulldown among other places.
    config.add_search_field("all_text_teim") do |field|
      field.label = 'All Fields'
      field.default = true
      field.solr_parameters = {
        :qt=>"search",
        :qf=>["all_text_teim"]
      }
    end

    config.add_search_field("search_title_info_search_title_teim") do |field|
      field.label = 'Title'
      field.solr_parameters = {
        :qt=>"title_search",
        :qf=>["search_title_info_search_title_teim"],
        :"spellcheck.dictionary" => "title"
      }
    end

    config.add_search_field("lib_name_teim") do |field|
      field.label = 'Name'
      field.solr_parameters = {
        :qt=>"name_search",
        :qf=>["lib_name_teim"],
        :"spellcheck.dictionary" => "name"
      }
    end

    config.add_search_field("clio_sim") do |field|
      field.label = 'CLIO ID'
      field.solr_parameters = {
        :qt=>"clio_search",
        :qf=>["clio_sim"],
        :"spellcheck.dictionary" => "clio"
      }
    end


    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field 'score desc, title_si asc, lib_date_dtsi desc', :label => 'relevance'
    config.add_sort_field 'lib_date_dtsi desc, title_si asc', :label => 'year'
    config.add_sort_field 'title_si asc, lib_date_dtsi desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config[:spell_max] = 5

    config.index.thumbnail_method = :thumbnail_url
  end

  def configure_for_seminars(config)

    configure_common(config)
    config.application_name = "University Seminars Digital Archive Alpha"
    (config.index.route ||= {}).merge!(controller: :seminars)
    (config.show.route ||= {}).merge!(controller: :seminars)
    configure_seminars_facets(config)
    config.add_facet_fields_to_solr_request!

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    #config.default_solr_params[:'facet.field'] = config.facet_fields.keys

    config.add_index_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label => "Title:"
    config.add_index_field "title_vern_ssm", :label => "Title:"
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_name', :displayable, type: :string), :label => "Names:"
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_repo_long', :symbol, type: :string), :label => "Repository:"
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_collection', :displayable), :label => "Collection:"
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_date_textual', :displayable, type: :string), :label => 'Date:'
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_format', :displayable), :label => "Format:"
    config.add_index_field "format_ssim", :label => "Routing:"
    config.add_index_field ActiveFedora::SolrService.solr_name('clio', :displayable), :label => "CLIO Id:"
    config.add_index_field "extent_ssm", :label => "Extent:"
    config.add_index_field ActiveFedora::SolrService.solr_name('lib_project_full', :symbol), :label => "Project:"
    config.add_index_field "published_ssm", :label => "Published:"
    config.add_index_field "object_ssm", :label => "In Fedora:"
    config.add_index_field "cul_member_of_ssim"
    config.add_index_field "index_type_label_ssi"
    config.add_index_field "resource_json"

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field ActiveFedora::SolrService.solr_name('title_display', :displayable, type: :string), :label=>"Title:"
    config.add_show_field "title_vern_ssm", :label=>"Title:"
    config.add_show_field "subtitle_ssm", :label=>"Subtitle:"
    config.add_show_field "subtitle_vern_ssm", :label=>"Subtitle:"
    config.add_show_field ActiveFedora::SolrService.solr_name('identifier', :symbol), :label => 'Identifier', :separator => '; '
    config.add_show_field "author_ssm", :label=>"Author:"
    config.add_show_field "author_vern_ssm", :label=>"Author:"
    config.add_show_field "lib_format_ssm", :label=>"Format:"
    config.add_show_field "format_ssim", :label=>"Routing:"
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_collection', :displayable), :label=>"Collection:"
    config.add_show_field ActiveFedora::SolrService.solr_name('lib_repo_full', :symbol, type: :string), :label=>"Repository:"
    config.add_show_field "url_fulltext_ssm", :label=>"URL:"
    config.add_show_field "url_suppl_ssm", :label=>"More Information:"
    config.add_show_field "material_type_ssm", :label=>"Physical Description:"
    config.add_show_field "published_ssm", :label=> "Published:"
    config.add_show_field "published_vern_ssm", :label=> "Published:"
    config.add_show_field "lc_callnum_ssm", :label=> "Call number:"
    config.add_show_field "object_ssm", :label=> "In Fedora:"
    config.add_show_field "isbn_ssim", :label=> "ISBN:"

  # "fielded" search configuration. Used by pulldown among other places.
    config.add_search_field("all_text_teim") do |field|
      field.label = 'All Fields'
      field.default = true
      field.solr_parameters = {
        :qt=>"search",
        :qf=>["all_text_teim"]
      }
    end

    config.add_search_field("title_teim") do |field|
      field.label = 'Title'
      field.solr_parameters = {
        :qt=>"title_search",
        :qf=>["title_teim"],
        :"spellcheck.dictionary" => "title"
      }
    end

    config.add_search_field("lib_name_teim") do |field|
      field.label = 'Seminar'
      field.solr_parameters = {
        :qt=>"name_search",
        :qf=>["lib_name_teim"],
        :"spellcheck.dictionary" => "name"
      }
    end


    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field 'score desc, title_si asc, lib_date_dtsi desc', :label => 'relevance'
    config.add_sort_field 'lib_date_dtsi desc, title_si asc', :label => 'year'
    config.add_sort_field 'title_si asc, lib_date_dtsi desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config[:spell_max] = 5

    config.index.thumbnail_method = :thumbnail_url
  end
end
end