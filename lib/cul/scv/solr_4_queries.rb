module Cul
  module Scv
    module Solr4Queries
      extend ActiveSupport::Concern
      
      def load_inbound_relationship(name, predicate, opts={})
        puts "name: #{name} predicate: #{predicate} opts: #{opts.inspect}"
        super
      end

      module ClassMethods
        
        def quote_for_solr2(value)
          '"' + value.gsub(/(:)/, '\\:').gsub(/(\/)/, '\\/').gsub(/"/, '\\"') + '"'
        end
        
        def relationship_query2(predicate, target_uri)
          "#{ActiveFedora::SolrService.solr_name(predicate, :symbol)}:#{escaped_uri(target_uri)}"
        end
        
        def search_model_clause2
          unless self == ActiveFedora::Base
            return relationship_query(:has_model, self.to_class_uri)
          end
        end
        
        def escaped_uri2(uri)
          uri.gsub(/(:)/, '\\:').gsub(/(\/)/, '\\/')
        end

        def escaped_pid2(pid)
          pid.gsub(/(([^\\]):)/,'\2\:')
        end
           
        def inbound_relationship_query2(pid,relationship_name)
          query = ""
          subject = :inbound
          if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name)
            predicate = relationships_desc[subject][relationship_name][:predicate]
            query = relationship_query(predicate, "info:fedora/#{pid}")
            if relationships_desc.has_key?(subject) && relationships_desc[subject].has_key?(relationship_name) && relationships_desc[subject][relationship_name].has_key?(:solr_fq)
              solr_fq = relationships_desc[subject][relationship_name][:solr_fq]
              query << " AND " unless query.empty?
              query << solr_fq
            end
          end
          query
        end
        
        def outbound_relationship_query2(relationship_name,outbound_pids)
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
        
        def construct_query_for_pids2(pid_array)
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