module Scv
	module MembersHelperBehavior
    def get_first_member(document, imageOnly=true)
      docs = get_members(document)
      docs.each do |doc|
        logger.info "#{doc["id"]}  #{doc["format"]}"
        if imageOnly
          if doc["format_ssi"] ==  "image"
            return [doc,docs.length]
          end
        else
          return [doc,docs.length]
        end
      end
      return [false,docs.length]
    end

    def get_members(document, format=:solr)
      memoize = (@document and document[:id] == @document[:id])
      return @members if memoize and not @members.nil?
      klass = false
      document[:has_model_ssim].each do |model|
        klass ||= ActiveFedora::Model.from_class_uri(model)
      end
      klass ||= GenericAggregator
      members = []
      if klass.include? Cul::Scv::Hydra::ActiveFedora::Model::Aggregator
        agg = klass.load_instance_from_solr(document[:id],document)
        r = agg.parts(:response_format => format)
        members = r.collect {|hit| SolrDocument.new(hit) } unless r.blank?
      end
      @members = members if memoize
      members
    end

    def get_rows(member_list, row_length)
  #    indexes = ((0...members.length).collect{|x| ((x % row_length)==0?x:nil}).compact
      indexes = []
      (0...member_list.length).collect {|x| if (x % row_length)==0 then  indexes.push x end}
      rows = []
      for index in indexes
        rows.push [index,index+1,index+2].collect {|x| member_list.at(x)?x:nil}
      end
      rows
    end

    def sort_member_docs(members)
      members.sort do |a,b|
        c = 0
        if (a['title_ssm'])
          c = ((a['title_ssm'][0] <=> b['title_ssm'][0]) || 0)
        end
        if (c == 0 and a['identifier_ssim'])
          a['identifier_ssim'].delete(a.id) unless a['identifier_ssim'].length == 1
          b['identifier_ssim'].delete(a.id) unless b['identifier_ssim'].length == 1
          a['identifier_ssim'][0] <=> b['identifier_ssim'][0]
        else
          c
        end
      end
    end
  end
end