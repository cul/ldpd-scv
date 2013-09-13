require 'deprecation'
module Scv
  module BlacklightHelperBehavior
    extend Deprecation
    include Hydra::BlacklightHelperBehavior
    def render_document_partial(doc, action_name, locals={})
      format = document_partial_name(doc)
      locals = locals.merge({:document=>doc})
      partial_name_parms = { :action_name => action_name, :format => format, :index_view_type => document_index_view_type }
      document_partial_path_templates.each do |str|
        partial = (str % partial_name_parms)
        if has_partial? partial
          return render :partial => partial, :locals=>locals
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
      display_type = document[blacklight_config.show.display_type]
      return 'default' unless display_type
      display_type = display_type.join(" ") if display_type.respond_to?(:join)
      "#{display_type.gsub("-"," ")}".parameterize("_").to_s
    end
    
  end
end