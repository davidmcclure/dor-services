def item_from_foxml(foxml, item_class = Dor::Base)
  foxml = Nokogiri::XML(foxml) unless foxml.is_a?(Nokogiri::XML::Node)
  xml_streams = foxml.xpath('//foxml:datastream')
  properties = Hash[foxml.xpath('//foxml:objectProperties/foxml:property').collect { |node| 
    [node['NAME'].split(/#/).last, node['VALUE']] 
  }]
  result = item_class.new(:pid => foxml.root['PID'])
  result.label = properties['label']
  result.inner_object.state = properties['state'][0..0]
  result.owner_id = properties['ownerId']
  xml_streams.each do |stream|
    content_node = stream.xpath('.//foxml:xmlContent/*').first.clone
    dsid = stream['ID']
    ds = result.datastreams[dsid]
    if ds.nil?
      ds = ActiveFedora::NokogiriDatastream.new
      result.add_datastream(ds)
    end
    if ds.is_a?(ActiveFedora::NokogiriDatastream)
      result.datastreams[dsid] = ds.class.from_xml(content_node, ds)
    else
      result.datastreams[dsid] = ds.class.from_xml(ds, stream)
    end
  end

  # stub item and datastream repo access methods
  result.datastreams.each_pair do |dsid,ds|
    ds.instance_eval do
      def content       ; self.ng_xml.to_s                 ; end
      def content=(val) ; self.ng_xml = Nokogiri::XML(val) ; end
      def save          ; return true                      ; end
    end
  end
  result.instance_eval do
    def save ; return true ; end
  end
  result
end
