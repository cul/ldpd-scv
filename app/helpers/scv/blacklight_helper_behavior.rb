require 'deprecation'
module Scv
  module BlacklightHelperBehavior
    extend Deprecation
    include Hydra::BlacklightHelperBehavior
    def render_document_partial(doc, action_name, locals={})
      format = document_partial_name(doc)
      locals = locals.merge({:document=>doc})
      if lookup_context.find_all("catalog/_#{action_name}_partials/_#{format}").any?
        render :partial=>"catalog/_#{action_name}_partials/#{format}", :locals=>locals
      else
        render :partial=>"catalog/_#{action_name}_partials/default", :locals=>locals
      end
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