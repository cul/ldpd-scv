module Cul
module Fedora
  TRIPLES_QUERY_TEMPLATE = <<-hd.gsub(/\s+/, " ").strip
select $predicate $object from <#ri>
where <info:fedora/$PID> $predicate $object
hd
  module Aggregators
    DESCRIPTION_QUERY_TEMPLATE = "select $description from <#ri> where $description <http://purl.oclc.org/NET/CUL/metadataFor> <info:fedora/$PID> order by $description".gsub(/\s+/, " ").strip

    module ImageAggregator
      MEMBER_QUERY_TEMPLATE = <<-hd.gsub(/\s+/, " ").strip
select $member $imageWidth $imageHeight $type $fileSize from <#ri> 
where $member <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/$PID> 
and $member <dc:format> $type
and $member <http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageWidth> $imageWidth 
and $member <http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageLength> $imageHeight 
and $member <http://purl.org/dc/terms/extent> $fileSize order by $fileSize
hd
      def gen_member_query(document)
        if @memberquery
          @memberquery
        else
          if document[:pid_ssi]
            if document[:pid_ssi].kind_of? String
              @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_ssi])
            else
              @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_ssi].first)
            end
          else
            _pid = document[:id]
            _pid = _pid.split('@')[0]
            @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,_pid)
          end
          @memberquery
        end
      end
    end
    module ContentAggregator
      MEMBER_QUERY_TEMPLATE = "select $member $type subquery( select $dctype $title from <#ri> where $member <dc:type> $dctype and $member <dc:title> $title) from <#ri> where $member <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/$PID> and $member <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> $type".gsub(/\s+/, " ").strip
      def gen_member_query(document)
        if @memberquery
          @memberquery
        else
          if document[:pid_ssi].kind_of? String
            @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_ssi])
          else
            @memberquery = MEMBER_QUERY_TEMPLATE.gsub(/\$PID/,document[:pid_ssi].first)
          end
          @memberquery
        end
      end
    end
  end
end