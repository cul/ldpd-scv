module Cul
module Fedora
  TRIPLES_QUERY_TEMPLATE = <<-hd.gsub(/\s+/, " ").strip
select $predicate $object from <#ri>
where <info:fedora/$PID> $predicate $object
hd

  module Objects
    class BaseObject
      include Cul::Fedora::UrlHelperBehavior
      def initialize(document, client=HTTPClient.new)
        @riurl = fedora_risearch_url
        @http_client = client
        if document[:pid_ssi].nil?
            _pid = document[:id].split('@')[0]
        else
          _pid = (document[:pid_ssi].kind_of? String) ? document[:pid_ssi] : document[:pid_ssi].first
        end
        @metadataquery = Cul::Fedora::Aggregator::DESCRIPTION_QUERY_TEMPLATE.gsub(/\$PID/,_pid)
        @triplesquery = Cul::Fedora::TRIPLES_QUERY_TEMPLATE.gsub(/\$PID/,_pid)
      end
      def riquery(query)
        query = {:query=>query}
        query[:format] = 'json'
        query[:type] = 'tuples'
        query[:lang] = 'itql'
        query[:limit] = nil
        res = @http_client.get_content(@riurl,query)
        JSON.parse(res)["results"]
      end
      def metadata_list
        @metadatas = riquery(@metadataquery) unless @metadatas
        @metadatas
      end
      def triples
        @triples = riquery(@triplesquery) unless @triples
        @triples
      end
    end
    class ContentObject < BaseObject
      include Cul::Fedora::Aggregator::ContentAggregator
      include Cul::Fedora::Objects
      attr :members
      def initialize(document, client)
        super
        gen_member_query(document)
      end
      def getsize
        if @size.nil?
          query = {:query=>@memberquery}
          query[:format] = 'count'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = @http_client.get_content(@riurl,query)
          @size = res.to_i
        end
        @size
      end
      def getmembers
        if @members.nil?
          query = {:query=>@memberquery}
          query[:format] = 'json'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = @http_client.get_content(@riurl,query)
          @members = JSON.parse(res)
        end
        @members
      end
    end
    class ImageObject < BaseObject
      include Cul::Fedora::Aggregator::ImageAggregator
      attr :members
      def initialize(document, client)
        super
        gen_member_query(document)
      end
      def getsize
        if @size.nil?
          query = {:query=>@memberquery}
          query[:format] = 'count'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = @http_client.get_content(@riurl,query)
          @size = res.to_i
        end
        @size
      end
      def getmembers
        if @members.nil?
          query = {:query=>@memberquery}
          query[:format] = 'json'
          query[:type] = 'tuples'
          query[:lang] = 'itql'
          query[:limit] = ''
          res = @http_client.get_content(@riurl,query)
          @members = JSON.parse(res)
        end
        @members
      end
    end
  end
end
end
