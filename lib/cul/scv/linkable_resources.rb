module Cul
  module Scv
    module LinkableResources
      # so as to avoid including all the url hepers via:
      ## include Rails.application.routes.url_helpers
      # we are just going to delegate
      delegate :fedora_content_path,  :to => 'Rails.application.routes.url_helpers'
      delegate :cache_path,  :to => 'Rails.application.routes.url_helpers'

      def http_client
        unless @http_client
          @http_client ||= HTTPClient.new
          @http_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
          uname = Cul::Fedora.repository.config[:user]
          pwd = Cul::Fedora.repository.config[:password]
          @http_client.set_auth(nil, uname, pwd)
        end
        @http_client
      end

      def linkable_resources
        r = self.parts(:response_format => :solr)
        return [] if r.blank?
        puts "r: " + r.inspect
        # puts "r[\"response\"]: " + r["response"]
        members = r.collect {|hit|
          SolrDocument.new(hit)
        }
        members.delete_if { |sd| (sd[:has_model_s] & ["info:fedora/ldpd:Resource"]).blank? }
        case self.route_as
        when "zoomingimage"
          results = members.collect {|doc| image_resource(doc)}
          base_id = self.pid
          url = Cul::Fedora::ResourceIndex.config[:riurl] + "/get/" + base_id + "/SOURCE"
          head_req = http_client().head(url)
          file_size = head_req.header["Content-Length"].first.to_i
          results << {
            :dimensions => "Original",
            :mime_type => "image/jp2",
            :show_path =>
              fedora_content_path(:download_method=>"show", :uri=>base_id, :block=>"SOURCE", :filename=>base_id + "_source.jp2"),
            :download_path =>
              fedora_content_path(:download_method=>"download", :uri=>base_id, :block=>"SOURCE", :filename=>base_id + "_source.jp2"),
            :content_models=>[]}  
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
        res[:show_path] = fedora_content_path(:download_method=>"show", :uri=>base_id, :block=>"CONTENT", :filename=>img_filename)
        res[:download_path] = fedora_content_path(:download_method=>"download", :uri=>base_id, :block=>"CONTENT", :filename=>img_filename)
        res[:dc_path] = fedora_content_path(:download_method=>"show_pretty", :uri=>base_id, :block=>"DC", :filename=>dc_filename)
        res[:cache_path] = cache_path(:download_method=>"show", :uri=>base_id, :block=>"CONTENT", :filename=>img_filename)
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
        res[:download_path] = fedora_content_path(:download_method=>"download", :uri=>base_id, :block=>"CONTENT", :filename=>filename)
        res[:dc_path] = fedora_content_path(:download_method=>"show_pretty", :uri=>base_id, :block=>"DC", :filename=>dc_filename)
        res
      end
      
    end

  end
end