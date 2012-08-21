module Cul
  module Scv
    module Solr4Queries
      extend ActiveSupport::Concern
      included do
      end
      
      module ClassMethods
        def escaped_uri(pid)
          "info\\:fedora\\/#{escaped_pid(pid)}"
        end
        
        def escaped_pid(pid)
          pid.gsub(/(:)/,'\\:')
        end
           
        def inbound_relationship_query(pid,relationship_name)
          query = ""
          subject = :inbound
          if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name)
            predicate = relationships_desc[subject][relationship_name][:predicate]
            query = "#{predicate}_s:#{escaped_uri(pid)}" 
            if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name) && relationships_desc[subject][relationship_name].has_key?(:solr_fq)
              solr_fq = relationships_desc[subject][relationship_name][:solr_fq]
              query << " AND " unless query.empty?
              query << solr_fq
            end
          end
          query
        end
        
        def outbound_relationship_query(relationship_name,outbound_pids)
          query = construct_query_for_pids(outbound_pids)
          subject = :self
          if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name) && relationships_desc[subject][relationship_name].has_key?(:solr_fq)
            solr_fq = relationships_desc[subject][relationship_name][:solr_fq]
            unless query.empty?
              #substitute in the filter query for each pid so that it is applied to each in the query
              query_parts = query.split(/OR/)
              query = ""
              query_parts.each_with_index do |query_part,index|
                query_part.strip!
                query << " OR " if index > 0
                query << "(#{query_part} AND #{solr_fq})"
              end
            else
              query = solr_fq
            end
          end
          query
        end
        
        def construct_query_for_pids(pid_array)
          query = ""
          pid_array.each_index do |i|
            query << "#{SOLR_DOCUMENT_ID}:#{escaped_pid(pid_array[i])}"
            query << " OR " if i != pid_array.length-1
          end
          query = "id:NEVER_USE_THIS_ID" if query.empty? || query == "id:"
          return query
        end
      end
    end
  end
end