# coding: utf-8
module Scv
  module ApplicationHelperBehavior
    def application_name
      "Columbia University Libraries Staff Collection Viewer Prototype"
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
    #
    # facet param helpers ->
    #

  # Return a normalized partial name that can be used to contruct view partial path
    def object_partial_name(object)
      # .to_s is necessary otherwise the default return value is not always a string
      # using "_" as sep. to more closely follow the views file naming conventions
      # parameterize uses "-" as the default sep. which throws errors
      display_type = object.class.name

      return 'default' unless display_type
      display_type = display_type.join(" ") if display_type.respond_to?(:join)

      "#{display_type.gsub("-"," ")}".parameterize("_").to_s
    end

    # given a doc and action_name, this method attempts to render a partial template
    # based on the value of doc[:format]
    # if this value is blank (nil/empty) the "default" is used
    # if the partial is not found, the "default" partial is rendered instead
    def render_object_partial(object, action_name, locals = {})
      format = object_partial_name(object)
      locals = locals.merge({:object=>object})
      begin
        render :partial=>"catalog/_#{action_name}_partials/#{format}", :locals=>locals
      rescue ActionView::MissingTemplate
        render :partial=>"catalog/_#{action_name}_partials/default", :locals=>locals
      end

    end
  end
end
