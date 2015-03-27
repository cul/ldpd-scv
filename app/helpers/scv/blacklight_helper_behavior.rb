require 'deprecation'
module Scv
  module BlacklightHelperBehavior
    extend Deprecation
    include Hydra::BlacklightHelperBehavior

    def application_name
      return blacklight_config.application_name if blacklight_config.application_name
      super
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

    ##
    # A list of document partial templates to try to render for a document
    #
    # The partial names will be interpolated with the following variables:
    #   - action_name: (e.g. index, show)
    #   - index_view_type: (the current view type, e.g. list, gallery)
    #   - format: the document's format (e.g. book) 
    #
    # @see #render_document_partial
    def document_partial_path_templates
      # first, the legacy template names for backwards compatbility
      # followed by the new, inheritable style
      # finally, a controller-specific path for non-catalog subclasses
      @partial_path_templates ||= [
        "%{action_name}_%{index_view_type}_%{format}",
        "%{action_name}_%{index_view_type}_default",
        "%{action_name}_%{format}",
        "%{action_name}_default",
        "#{controller_name}/%{action_name}_%{format}",
        "#{controller_name}/_%{action_name}_partials/%{format}",
        "#{controller_name}/_%{action_name}_partials/default",
        "catalog/%{action_name}_%{format}",
        "catalog/_%{action_name}_partials/%{format}",
        "catalog/_%{action_name}_partials/default"]
    end

    def render_document_partial(doc, action_name, locals={})
      format = document_partial_name(doc)
      locals = locals.merge({:document=>doc})
      partial_name_parms = { :action_name => action_name, :format => format, :index_view_type => document_index_view_type }
      document_partial_path_templates.each do |str|
        partial = (str % partial_name_parms)
        if has_partial? partial
          begin
            return render :partial => partial, :locals=>locals
          rescue Exception => e
            puts e.message
            puts e.backtrace.join("\n")
            puts doc.inspect
          end
        end
      end
      return ''
    end

    def has_partial? ppath
      i = ppath.rindex('/')
      if i
        ppath = ppath.slice(0...i+1) + '_' + ppath.slice(i+1...ppath.length)
      end
#      return lookup_context.find_all(ppath).any?
      return lookup_context.exists?(ppath)
    end

    def document_partial_name(document)
      # .to_s is necessary otherwise the default return value is not always a string
      # using "_" as sep. to more closely follow the views file naming conventions
      # parameterize uses "-" as the default sep. which throws errors
      display_type = document[blacklight_config.show.display_type_field]
      return 'default' unless display_type
      display_type = display_type.join(" ") if display_type.respond_to?(:join)
      "#{display_type.gsub("-"," ")}".parameterize("_").to_s
    end
    
    def index_title_text(document)
      text = ""
      if document["lib_date_ssm"]
        text += ("&nbsp;&nbsp;" + document["lib_date_ssm"][0] + ".")
      end
      if document["lib_name_ssm"]
        text += ("&nbsp;&nbsp;" + document["lib_name_ssm"][0] + ".")
      end
      if document["extent_ssi"]
        text += ("&nbsp;&nbsp;" + document["extent_ssi"][0] + ".")
      end
      if document["lib_repo_ssm"]
        text += ("&nbsp;&nbsp;" + document["lib_repo_ssm"][0] + ".")
      end
      if document["lib_collection_ssm"]
        text += ("&nbsp;&nbsp;- " + document["lib_collection_ssm"].join(',') + ".")
      end
      text.squeeze('.').html_safe
    end

    def render_document_index_label doc, opts
      label = nil
      label ||= doc.link_title(opts[:label]) if opts[:label].is_a? String
      label ||= doc.link_title(opts[:label]) if opts[:label].instance_of? Symbol
      # label ||= doc.get(opts[:label], :sep => nil) if opts[:label].instance_of? Symbol
      label ||= opts[:label].call(doc, opts) if opts[:label].instance_of? Proc
      label ||= opts[:label] if opts[:label].is_a? String
      label ||= doc.id
      presenter(doc).render_field_value label
    end

    def render_document_heading(*args)
      options = args.extract_options!
      if args.first.is_a? SolrDocument
        document = args.shift
        tag = options[:tag]
      else
        document = nil
        tag = args.first || options[:tag]
      end

      tag ||= :h4

      content_tag(tag, render_field_value(document_heading(document)), class: 'documentTitle')
    end

    def is_default_search?(search)
      unless search.is_a? Blacklight::Configuration::SearchField
        search = blacklight_config.search_fields[search.to_s]
      end
      return search.nil? ? false : search.default
    end
  end
end