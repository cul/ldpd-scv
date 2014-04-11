module Cul
  module Scv
    module ImageDimensions

      def long
        @long_side ||= max(width(), length())
      end

      def width
        @width ||= begin
          ds = datastreams["content"]
          width = 0
          unless ds.nil? or rels_int.relationships(ds,:exif_image_width).blank?
            width = rels_int.relationships(ds,:exif_image_width).first.object.to_s.to_i
          end
          width = relationships(:image_width).first.to_s.to_i if width == 0
          width
        end
      end

      def length
        @length ||= begin
          ds = datastreams["content"]
          length = 0
          unless ds.nil? or rels_int.relationships(ds,:exif_image_length).blank?
            length = rels_int.relationships(ds,:exif_image_length).first.object.to_s.to_i
          end
          length = relationships(:image_length).first.to_s.to_i if length == 0
          length
        end
      end
    end
  end
end