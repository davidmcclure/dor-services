require 'active_fedora'
require 'datastreams/identity_metadata_ds'
require 'datastreams/simple_dublin_core_ds'
require 'datastreams/workflow_ds'
require 'dor/suri_service'

module Dor

  class Base < ::ActiveFedora::Base
    
    attr_reader :workflows


    has_metadata :name => "identityMetadata", :type => IdentityMetadataDS
    has_metadata :name => "descMetadata", :type => ActiveFedora::NokogiriDatastream
    has_metadata :name => "rightsMetadata", :type => ActiveFedora::NokogiriDatastream
    has_metadata :name => "technicalMetadata", :type => ActiveFedora::NokogiriDatastream
    has_metadata :name => "contentMetadata", :type => ActiveFedora::NokogiriDatastream
    has_metadata :name => "DC", :type => SimpleDublinCoreDs
    has_metadata :name => "RELS-EXT", :type => ActiveFedora::NokogiriDatastream
    has_metadata :name => "identityMetadata", :type => IdentityMetadataDS
    has_metadata :name => "technicalMetadata", :type => ActiveFedora::NokogiriDatastream

    def initialize(attrs = {})
      unless attrs[:pid]
        attrs = attrs.merge!({:pid=>Dor::SuriService.mint_id})  
        @new_object=true
      else
        @new_object = attrs[:new_object] == false ? false : true
      end
      @inner_object = Fedora::FedoraObject.new(attrs)
      @datastreams = {}
      @workflows = {}
      configure_defined_datastreams
    end  

    def identity_metadata
      if self.datastreams.has_key?('identityMetadata')
        IdentityMetadata.from_xml(self.datastreams['identityMetadata'].content)
      else
        nil
      end
    end
    
    def public_xml      
      pub = Nokogiri::XML("<publicObject/>").root
      pub['id'] = pid
      pub.add_child(self.datastreams['identityMetadata'].ng_xml.root.clone)
      pub.add_child(self.datastreams['contentMetadata'].ng_xml.root.clone)
      pub.add_child(self.datastreams['rightsMetadata'].ng_xml.root.clone)
      pub.add_child(generate_dublin_core.root)
      pub.to_xml {|config| config.no_declaration}
    end
    
    # Generates Dublin Core from the MODS in the descMetadata datastream using the LoC mods2dc stylesheet
    # Should not be used for the Fedora DC datastream
    def generate_dublin_core
      xslt = Nokogiri::XSLT(File.new(File.expand_path(File.dirname(__FILE__) + '/mods2dc.xslt')) )
      xslt.transform(self.datastreams['descMetadata'].ng_xml)
    end
    
    def publish_metadata
      DigitalStacksService.transfer_to_document_store(pid, self.datastreams['identityMetadata'].to_xml, 'identityMetadata')
      DigitalStacksService.transfer_to_document_store(pid, self.datastreams['contentMetadata'].to_xml, 'contentMetadata')
      DigitalStacksService.transfer_to_document_store(pid, self.datastreams['rightsMetadata'].to_xml, 'rightsMetadata')
      dc_xml = self.generate_dublin_core.to_xml {|config| config.no_declaration}
      DigitalStacksService.transfer_to_document_store(pid, dc_xml, 'DC')
      DigitalStacksService.transfer_to_document_store(pid, public_xml, 'public')
    end
    
    # Self-aware datastream builders
    def build_datastream(datastream, force = false)
      ds = datastreams[datastream]
      if force or (datastreams_in_fedora.has_key?(datastream) == false) or (ds.content.to_s.empty?)
        proc = "build_#{datastream}_datastream".to_sym
        content = self.send(proc, ds)
        ds.save
      end
      return ds
    end

  end
end