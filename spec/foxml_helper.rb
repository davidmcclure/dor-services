def item_from_foxml(foxml, item_class = Dor::Base)
  foxml = Nokogiri::XML(foxml) unless foxml.is_a?(Nokogiri::XML::Node)
  xml_streams = foxml.xpath('//foxml:datastream')
  properties = Hash[foxml.xpath('//foxml:objectProperties/foxml:property').collect { |node| 
    [node['NAME'].split(/#/).last, node['VALUE']] 
  }]
  result = item_class.new(:pid => foxml.root['PID'])
  result.label = properties['label']
  result.owner_id = properties['ownerId']
  xml_streams.each do |stream|
    begin
    content = stream.xpath('.//foxml:xmlContent/*').first.to_xml
    dsid = stream['ID']
    ds = result.datastreams[dsid]
    if ds.nil?
      ds = ActiveFedora::OmDatastream.new(result,dsid)
      result.add_datastream(ds)
    end
  
    
    if ds.is_a?(ActiveFedora::OmDatastream)
      result.datastreams[dsid] = ds.class.from_xml(Nokogiri::XML(content), ds)
    elsif ds.is_a?(ActiveFedora::RelsExtDatastream)
      result.datastreams[dsid] = ds.class.from_xml(content, ds)
    else
      result.datastreams[dsid] = ds.class.from_xml(ds, stream)
    end
  rescue
    #rescue if 1 datastream failed 
  end
  end

  # stub item and datastream repo access methods
  result.datastreams.each_pair do |dsid,ds|
    if ds.is_a?(ActiveFedora::OmDatastream) and not ds.is_a?(Dor::WorkflowDs)
      ds.instance_eval do
#        def content       ; self.ng_xml.to_s                 ; end
#        def content=(val) ; self.ng_xml = Nokogiri::XML(val) ; end
      end
    end
    ds.instance_eval do
      def save          ; return true                      ; end
    end
  end
  result.instance_eval do
    def save ; return true ; end
  end
  result
end

