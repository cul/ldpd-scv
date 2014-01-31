module Scv
  module StructMetadataHelperBehavior
    def struct_metadata(doc)
      pid = base_id_for(doc)
      members = get_members(doc)

      xml = rubydora.datastream_dissemination(:pid=>pid, :dsid=>'structMetadata')
      ds = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.from_xml(xml)
      node_map = {}
      ds.divs_with_attribute(true,'CONTENTIDS').each do |node|
        node_map[node['CONTENTIDS']] = node
      end
      
      map = {}
      members.each do |doc|
        ids = (Array(doc[:identifier_ssim]) + Array(doc[:dc_identifier_ssim])).uniq
        node_map.each do |cid, node|
          if ids.include? cid
            node['pid'] = doc[:id]
            map[doc[:id]] = doc
          end
        end
      end
      [ds, map]
    end
  end
end