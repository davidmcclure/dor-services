module Dor
  module Versionable
    extend ActiveSupport::Concern
    include Processable
    
    included do
      has_metadata :name => 'versionMetadata', :type => Dor::VersionMetadataDS, :label => 'Version Metadata'
    end
    
    def open_new_version
      raise DorException, 'Object net yet accessioned' unless(Dor::WorkflowService.get_lifecycle('dor', pid, 'accessioned'))
      raise DorException, 'Object already opened for versioning' if(Dor::WorkflowService.get_active_lifecycle('dor', pid, 'opened'))

      datastreams['versionMetadata'].increment_version
      instantiate_workflow('versioningWF')
    end
    
    def current_version
      datastreams['versionMetadata'].current_version_id
    end
    
  end
end