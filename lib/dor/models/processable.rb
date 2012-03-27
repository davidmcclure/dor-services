module Dor
  module Processable
    extend ActiveSupport::Concern
    include SolrDocHelper

    included do
      # TODO: Remove placeholder :url parameter once ticket HYDRA-745 is satisfactorily resolved
      has_metadata :name => 'workflows', :type => Dor::WorkflowDs, :label => 'Workflows', :control_group => 'E'
      self.ds_specs.instance_eval do
        class << self
          alias_method :_retrieve, :[]
          def [](key)
            self._retrieve(key) || (key =~ /WF$/ ? { :type => Dor::WorkflowDs } : nil)
          end
        end
      end
      after_initialize :set_workflows_datastream_location
    end
    
    def set_workflows_datastream_location
      if self.workflows.new?
        workflows.mimeType = 'application/xml'
        workflows.dsLocation = File.join(Dor::Config.workflow.url,"dor/objects/#{self.pid}/workflows")
      end
    end
    
    # Self-aware datastream builders
    def build_datastream(datastream, force = false)
      ds = datastreams[datastream]
      path = Druid.new(self.pid).path(Dor::Config.stacks.local_workspace_root)
      filename = File.join(path,"#{datastream}.xml")
      if File.exists?(filename)
        content = File.read(filename)
        ds.content = content
        ds.ng_xml = Nokogiri::XML(content) if ds.respond_to?(:ng_xml)
        ds.save unless ds.digital_object.new?
      elsif force or ds.new_object? or (ds.content.to_s.empty?)
        proc = "build_#{datastream}_datastream".to_sym
        if respond_to? proc
          content = self.send(proc, ds)
          ds.save unless ds.digital_object.new?
        end
      end
      return ds
    end

    def cleanup()
      CleanupService.cleanup(self)
    end

    def milestones
      Dor::WorkflowService.get_milestones('dor',self.pid)
    end
    
    def to_solr(solr_doc=Hash.new, *args)
      super(solr_doc, *args)
      self.milestones.each do |milestone|
        timestamp = milestone[:at].utc.xmlschema
        add_solr_value(solr_doc, 'lifecycle', milestone[:milestone], :string, [:searchable, :facetable])
        add_solr_value(solr_doc, 'lifecycle', "#{milestone[:milestone]}:#{timestamp}", :string, [:displayable])
        add_solr_value(solr_doc, milestone[:milestone], timestamp, :date, [:searchable, :facetable, :sortable])
      end
      solr_doc
    end
  end
end
