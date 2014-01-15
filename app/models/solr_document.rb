# -*- encoding : utf-8 -*-
class SolrDocument 

  include Blacklight::Solr::Document
  
  # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_ssm
  extension_parameters[:marc_format_type] = :marcxml
  
  # Email uses the semantic field mappings below to generate the body of an email.
  use_extension( Blacklight::Solr::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Solr::Document::DublinCore)    
  field_semantics.merge!(    
                         :title => "title_display_ssm",
                         :author => "author_ssm",
                         :language => "language_sim",
                         :format => "lib_format_ssm"
                         )

  def link_title(link_field = nil)
    begin
      @link_title ||= (
        (link_field and self[link_field] and self[link_field].first) or
        (self["title_display_ssm"] and self["title_display_ssm"].first) or
        (self["dc_title_ssm"] and self["dc_title_ssm"].first) or
        (self["object_profile_ssm"] and JSON.parse(self["object_profile_ssm"])["objLabel"]) or
        self[:id]).strip.sub(/[\W]$/,'')
    rescue
      @link_title = "untitled or needs reindex"
    end
  end
end
