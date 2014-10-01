module Cul::Scv::CatalogBehavior
  extend ActiveSupport::Concern
  module ClassMethods
  end
  # single document image resource
  def image
  end
  
  # single document availability status (true/false)
  def status
  end
  
  # single document availability info
  def availability
  end
  
  # collection/search UI via Google maps
  def map
  end

  def cache_docs
    Thread.current[:doc_cache] = {}
  end

  def uncache_docs
    Thread.current[:doc_cache].clear
    Thread.current[:doc_cache] = nil
  end

  def show
    @response, @document = get_solr_response_for_doc_id

    respond_to do |format|
      format.html {setup_next_and_previous_documents}

      format.json { render json: {response: {document: @document}}}

      @document.export_formats.each_key do | format_name |
          format.send(format_name.to_sym) {render :text => @document.export_as(format_name), :layout=>false}
      end
    end
  end
end
