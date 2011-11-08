require 'active_fedora'
require 'datastreams/identity_metadata_ds'
require 'datastreams/simple_dublin_core_ds'
require 'datastreams/workflow_ds'
require 'dor/suri_service'

module Dor

  class Base < ::ActiveFedora::Base
    
    attr_reader :workflows

    has_metadata :name => "DC", :type => SimpleDublinCoreDs, :label => 'Dublin Core Record for this object'
    has_metadata :name => "RELS-EXT", :type => ActiveFedora::RelsExtDatastream, :label => 'RDF Statements about this object'
    has_metadata :name => "identityMetadata", :type => IdentityMetadataDS, :label => 'Identity Metadata'

    # Make an idempotent API-M call to get gsearch to reindex the object
    def self.touch(*pids)
      client = Dor::Config.fedora.client
      pids.collect { |pid|
        response = begin
          client["objects/#{pid}?state=A"].put('', :content_type => 'text/xml')
        rescue RestClient::ResourceNotFound
          doc = Nokogiri::XML("<update><delete><id>#{pid}</id></delete></update>")
          Dor::Config.gsearch.client['update'].post(doc.to_xml, :content_type => 'application/xml')
        end
        response.code
      }
    end
    
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
    
    # Self-aware datastream builders
    def build_datastream(datastream, force = false)
      ds = datastreams[datastream]
      if force or ds.new_object? or (ds.content.to_s.empty?)
        proc = "build_#{datastream}_datastream".to_sym
        content = self.send(proc, ds)
        ds.save
      end
      return ds
    end
    
    def reindex
      Dor::SearchService.reindex(self.pid)
    end

  end
end