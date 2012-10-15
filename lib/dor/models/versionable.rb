module Dor
  module Versionable
    extend ActiveSupport::Concern
    include Processable
    include Upgradable
    
    included do
      has_metadata :name => 'versionMetadata', :type => Dor::VersionMetadataDS, :label => 'Version Metadata', :autocreate => true
    end
    
    def open_new_version
      raise Dor::Exception, 'Object net yet accessioned' unless(Dor::WorkflowService.get_lifecycle('dor', pid, 'accessioned'))
      raise Dor::Exception, 'Object already opened for versioning' if(new_version_open?)

      ds = datastreams['versionMetadata']
      ds.increment_version
      ds.content = ds.ng_xml.to_s
      ds.save unless self.new_object? 
      initialize_workflow 'versioningWF'
    end
    
    def current_version
      datastreams['versionMetadata'].current_version_id
    end
    
    # Sets versioningWF:submit-version to completed and initiates accessionWF for the object
    # @raise [Dor::Exception] if the object hasn't been opened for versioning, or if accessionWF has
    #   already been instantiated
    def close_version
      raise Dor::Exception, 'Trying to close version on an object not opened for versioning' unless(new_version_open?)
      raise Dor::Exception, 'accessionWF already created for versioned object' if(Dor::WorkflowService.get_active_lifecycle('dor', pid, 'submitted'))

      Dor::WorkflowService.update_workflow_status 'dor', pid, 'versioningWF', 'submit-version', 'completed'
      initialize_workflow 'accessionWF'
    end

    # @return [Boolean] true if 'opened' lifecycle is active, false otherwise
    def new_version_open?
      return false if(Dor::WorkflowService.get_active_lifecycle('dor', pid, 'opened').nil?)
      true
    end

    # Following chart of processes on this consul page: https://consul.stanford.edu/display/chimera/Versioning+workflows
    alias_method :start_version,  :open_new_version
    alias_method :submit_version, :close_version
    
  end
end