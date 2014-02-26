require 'cul'
require 'rubydora'
require 'active-fedora'
namespace :cul do
namespace :util do
  def get_term(doc, ptr)
    begin
      return doc.term_values(*ptr)
    rescue
      []
    end
  end
  desc "configure AF"
  task :configure => :environment do
    ENV['RAILS_ENV'] ||= 'development'
    ActiveFedora.init :fedora_config_path =>"config/fedora.yml", :solr_config_path => "config/solr.yml"
  end
  desc "iterate over a list of pids adding project title if necessary"
  task :add_project => :configure do
    p_title = ENV['TITLE']
    yield unless p_title
    fpath = ENV['LIST']
    yield unless fpath and File.exist? fpath
    ns = {'mods'=>'http://www.loc.gov/mods/v3'}
    # do the work!
    IO.foreach(fpath) do |objuri|
      objuri.strip!
      begin
        o = ContentAggregator.find(objuri)
        xml = o.descMetadata.ng_xml
        coll = xml.xpath('/mods:mods/mods:relatedItem[@displayLabel=\'Collection\']')
        project = xml.xpath('/mods:mods/mods:relatedItem[@displayLabel=\'Project\']')

        if !project.empty?
          puts "skipping #{o.pid} = #{project[0].text}"
          next
        end
        if coll.empty?
          puts "skipping #{o.pid} (no collection)"
          next
        end

        coll = coll[0]
        new_related = Nokogiri::XML::Node.new("mods:relatedItem", xml)
        new_related['displayLabel'] = 'Project'
        new_related['type'] = 'host'
        coll.add_next_sibling(new_related)
        new_title_info = Nokogiri::XML::Node.new("mods:titleInfo", xml)
        new_title =  Nokogiri::XML::Node.new("mods:title", xml)
        new_related.add_child new_title_info
        new_title_info.add_child new_title 
        new_title.add_child Nokogiri::XML::Text.new(p_title, xml)
        project = xml.xpath('/mods:mods/mods:relatedItem[@displayLabel=\'Project\']')
        if (!project.empty?)
          puts "success #{o.pid} = #{project[0].text}"
          o.descMetadata.content = xml.to_xml
          o.save
        else
          puts "failure #{o.pid}"
        end
      rescue Exception=>e
        puts "error adding project to #{objuri}"
      end
    end
  end
  desc "iterate over a file of fedora uri's, moving DC metadata to mods if necessary"
  task :correct_metadata => :configure do
    fpath = ENV['LIST']
    yield unless fpath and File.exist? fpath
    # mods pointers
    mods_title_ptr = [:mods, :main_title_info, :main_title]
    mods_format_ptr = [:physical_description, :form_nomarc]
    mods_project_ptr = [:project, :title_info, :title]
    mods_id_ptr = [:identifier]
    mods_clio_ptr = [:clio]
    mods_project_ptr = [:lib_project]
    mods_repo_ptr = [:location, :repo_code]
    # dc pointers
    dc_title_ptr = [:dc, :dc_title]
    dc_id_ptr = [:dc, :dc_identifier]
    dc_clio_ptr = [:dc, :dc_relation]

    # do the work!
    IO.foreach(fpath) do |objuri|
      objuri.strip!
      begin
        obj = ActiveFedora::Base.load_instance(objuri)
        cmodel = ActiveFedora::ContentModel.known_models_for(obj).first
        obj = cmodel.load_instance(objuri)
        logger.info "#{objuri} (#{cmodel})"
        descMetadata = obj.datastreams["descMetadata"]
        descMetadata.ensure_xml_loaded
        mods_doc = descMetadata.ng_xml
        mods_xml = descMetadata.to_xml
        dc = obj.datastreams["DC"]
        dc_title = get_term(dc, dc_title_ptr)
        dc_ids = get_term(dc, dc_id_ptr).delete_if { |x| (x == obj.pid or x == obj.internal_uri)}
        main_title = get_term(descMetadata, mods_title_ptr)
        ids = get_term(descMetadata, mods_id_ptr)
        clio = get_term(descMetadata, mods_clio_ptr)
        repo = get_term(descMetadata, mods_repo_ptr)
        format = get_term(descMetadata,mods_format_ptr)
        project = get_term(descMetadata, mods_project_ptr)
        logger.info "title before: #{get_term(descMetadata, mods_title_ptr).inspect}"
        logger.info "clio before: #{clio.inspect}"
        logger.info "ids before: #{get_term(descMetadata, mods_id_ptr).inspect}"
        logger.info "format before: #{format.inspect}"
        logger.info "project before: #{project.inspect}"
        # add a main title
        if main_title.empty?
          title_info = mods_doc.create_element "titleInfo"
          title_val = dc_title.first || dc_ids.first || obj.pid
          title = mods_doc.create_element "title", title_val
          title_info.add_child(title)
          mods_doc.root.add_child(title_info)
          # none attribute bug prevents update_values
          #descMetadata.update_values(mods_title_ptr => title_val)
        end
        # add clio ids if present
        if clio.empty?
          dc_clio = dc.term_values(*dc_clio_ptr) || []
          dc_clio = dc_clio.delete_if {|x| not(x =~ /clio:/)}
          dc_clio.each { |val|
            val = val.split(':')[-1]
            node = mods_doc.create_element "identifier", {:type=>'CLIO'}, val
            mods_doc.root.add_child(node)
            clio = get_term(descMetadata,mods_clio_ptr)
          }
        end
        # add local ids
        if ids.empty?
          dc_ids.each { |x|
            node = mods_doc.create_element "identifier", {:type=>'local'}, x
            mods_doc.root.add_child(node)
          }
        end
        # build format for intellectual objects
        unless obj.is_a? Resource
          if format.empty?
            #descMetadata.update_values(mods_format_ptr => "oral histories")
            pd = mods_doc > "physicalDescription"
            unless pd.first
              mods_doc.root.add_child mods_doc.create_element "physicalDescription"
              pd = mods_doc.root > "physicalDescription"
            end
            pd.first.add_child mods_doc.create_element("form", {:authority=>'local'}, "oral histories")
            format = get_term(descMetadata,mods_format_ptr)
          end
        end
        # put it in the project
        if project.empty?
          project_host = mods_doc.root.add_child( mods_doc.create_element("relatedItem", {:type=>'host', :displayLabel=>"Project"}))
          title_info = project_host.add_child(mods_doc.create_element("titleInfo"))
          title_info.add_child(mods_doc.create_element("title","Preserving Historic Audio Content"))
          project = get_term(descMetadata, mods_project_ptr)
        end
        # put it in the COH repo
        if repo.empty?
          location = mods_doc > "location"
          unless location.first
            mods_doc.root.add_child mods_doc.create_element("location")
            location = mods_doc.root > "location"
          end
          location.first.add_child mods_doc.create_element("physicalLocation", {:authority => 'marcorg'}, "NyNyCOH")
          repo = get_term(descMetadata, mods_repo_ptr)
        end
        logger.info "title after: #{get_term(descMetadata, mods_title_ptr).inspect}"
        logger.info "clio after: #{clio.inspect}"
        logger.info "ids after: #{get_term(descMetadata, mods_id_ptr).inspect}"
        logger.info "format after: #{format.inspect}"
        logger.info "project after: #{project.inspect}"
        logger.info "repo after: #{repo.inspect}"
        xml = descMetadata.to_xml
        if (mods_xml != xml)
          descMetadata.content = xml
          obj.save
        end
      rescue => error
        logger.error "error #{objuri} -> #{error}"
        logger.info error.backtrace.join "\n"
      end
    end
  end
  desc "iterate over a file of fedora uri's, checking the CONTENT dsLocations"
  task :correct_resources => :configure do
    fpath = ENV['LIST']
    yield unless fpath and File.exist? fpath
    dsid = "CONTENT"
    bad_path = /\/fstore\/ldpd\/mellon-audio-pres\/final\//
    good_path = '/fstore/archive/ldpd/preservation/mellon_audio_2010/data/'
    IO.foreach(fpath) do |objuri|
      objuri.strip!
      begin
        resource = Resource.load_instance(objuri)
        obj_changed = false
        # ensure that we have RestrictedResource cModel
        old_models = resource.ids_for_outbound :has_model
        unless old_models.include? "ldpd:RestrictedResource"
          resource.add_relationship(:has_model, "info:fedora/ldpd:RestrictedResource")
          new_models = resource.ids_for_outbound(:has_model).inspect
          obj_changed = (old_models != new_models)
          logger.info "updated cModels -> #{new_models.inspect}" if obj_changed
        end
        # create a Rubydora datastream, so that we're not snagged by no content
        rds = Rubydora::Datastream.new(resource.inner_object, dsid)
        dsLocation = rds.dsLocation.dup if rds.dsLocation
        dsLocation ||= "<ERROR: MISSING>"
        logger.info "#{objuri} -> #{dsLocation}"
        ds_changed = false
        if dsLocation =~ bad_path
          dsLocation.sub! bad_path, good_path
          rds.dsLocation = dsLocation
          ds_changed = true
          logger.info "changed #{objuri}.dsLocation -> #{rds.dsLocation}"
        end
        if rds.dsState == 'I'
          rds.dsState = 'A'
          logger.info "changed #{objuri}.dsState -> #{rds.dsState}"
          ds_changed = true
        end
        if ds_changed
          rds.save
        end
        if obj_changed
          resource.save
        end
      rescue => error
        logger.error "error #{objuri} -> #{error}"
        logger.info error.backtrace.join "\n"
      end
    end
  end
  desc "migrate SOURCE ds to content ds"
  task :migrate_source => :configure do
    pid = ENV['PID']
    o = GenericResource.find(pid)
    old_ds = o.datastreams['SOURCE']
    opts = {:controlGroup => old_ds.controlGroup, :mimeType =>old_ds.mimeType}
    if o.datastreams['content'].nil? or o.datastreams['content'].new?
      new_ds = o.create_datastream(ActiveFedora::Datastream, 'content', opts)
      new_ds.dsLocation = old_ds.dsLocation
      new_ds.save
    end
    if (opts[:mimeType] == 'image/jp2' and o.rels_int.relationships(new_ds,:foaf_zooming).blank?)
      o.rels_int.add_relationship(new_ds,:foaf_zooming, o.internal_uri + "/content")
    end
    subject = RDF::URI.new(o.internal_uri)
    cmodel_pred = ActiveFedora::Predicates.find_graph_predicate(:has_model)
    type_pred = ActiveFedora::Predicates.find_graph_predicate(:rdf_type)
    agg_model = RDF::URI.new("info:fedora/ldpd:JP2ImageAggregator")
    res_model = RDF::URI.new("info:fedora/ldpd:GenericResource")
    del_stmt = RDF::Statement.new(subject, cmodel_pred, agg_model)
    add_stmt = RDF::Statement.new(subject, cmodel_pred, res_model)
    o.remove_relationship(cmodel_pred, agg_model)
    o.add_relationship(cmodel_pred, res_model)
    o.remove_relationship(type_pred, RDF::URI.new("http://purl.oclc.org/NET/CUL/Aggregator"))
    o.add_relationship(type_pred, RDF::URI.new("http://purl.oclc.org/NET/CUL/Resource"))
    o.save
  end
end
end
