module Cul
  module Scv
    module LinkableResources
      def linkable_resources(format=:solr)
        r = self.parts(:response_format => format)
        return [] if r.blank?
        members = r["response"]["docs"].collect {|hit|
          SolrDocument.new(hit)
        }
        members.delete_if { |sd| (sd[:has_model_s] & ["info:fedora/ldpd:Resource"]).blank? }
        case self.route_as
          when "zoomingimage"
            results = members.collect {|doc| image_resource(doc)}
            base_id = base_id_for(document)
            url = Cul::Fedora::ResourceIndex.config[:riurl] + "/get/" + base_id + "/SOURCE"
            head_req = http_client.head(url)
            file_size = head_req.header["Content-Length"].first.to_i
            results << {:dimensions => "Original", :mime_type => "image/jp2", :show_path => fedora_content_path("show", base_id, "SOURCE", base_id + "_source.jp2"), :download_path => fedora_content_path("download", base_id , "SOURCE", base_id + "_source.jp2"), :content_models=>[]}  
          when "audio"
            results = members.collect {|doc| audio_resource(doc)}
          when "image"
            results = members.collect {|doc| image_resource(doc)}
          else
            raise "Unknown format #{format}"
          end
          return results
      end
      
      def basic_resource(document)
        res = {}
        res[:pid] = document["id"]
        res[:dsid] = "CONTENT"
        res[:mime_type] = document["dc_format_t"] ? document["dc_format_t"].first : "application/octect-stream"
        res[:content_models] = document["has_model_s"]
        res[:file_size] = document["extent_s"].first.to_i
        res[:size] = (document["extent_s"].first.to_i / 1024).to_s + " Kb"
        res
      end

      def image_resource(document)
        res = basic_resource(document)
        if document["image_width_s"]
          res[:dimensions] = document["image_width_s"].first + " x " + document["image_length_s"].first
          res[:width] = document["image_width_s"].first
          res[:height] = document["image_length_s"].first
        else
          res[:dimensions] = "? x ?"
          res[:width] = "0"
          res[:height] = "0"
        end
        base_id = document["id"]
        base_filename = base_id.gsub(/\:/,"")
        img_filename = base_filename + "." + document["dc_format_t"].first.gsub(/^[^\/]+\//,"")
        dc_filename = base_filename + "_dc.xml"
        res[:image_file_name] = img_filename
        res[:dc_file_name] = dc_filename
        #res[:show_path] = fedora_content_path("show", base_id, "CONTENT", img_filename)
        #res[:cache_path] = cache_path("show", base_id, "CONTENT", img_filename)
        #res[:download_path] = fedora_content_path("download", base_id, "CONTENT", img_filename)
        #res[:dc_path] = fedora_content_path('show_pretty', base_id, "DC", dc_filename)
        res
      end

      def audio_resource(document)
        res = basic_resource(document)
        base_id = document["id"]
        base_filename = base_id.gsub(/\:/,"")
        if res[:mime_type] =~ /wav/
          ext = 'wav'
        elsif res[:mime_type] =~ /mpeg/
          ext = 'mp3'
        else
          ext = 'bin'
        end
        filename = base_filename + "." + ext
        dc_filename = base_filename + "_dc.xml"
        res[:download_path] = fedora_content_path("download", base_id, "CONTENT", filename)
        res[:dc_path] = fedora_content_path('show_pretty', base_id, "DC", dc_filename)
        res
      end
      
    end
  end
end