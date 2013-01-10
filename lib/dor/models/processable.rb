require 'equivalent-xml'

module Dor
  module Processable
    extend ActiveSupport::Concern
    include SolrDocHelper
    include Upgradable

    included do
      has_metadata :name => 'workflows', :type => Dor::WorkflowDs, :label => 'Workflows', :control_group => 'E'
      after_initialize :set_workflows_datastream_location
    end

    def set_workflows_datastream_location
      if self.workflows.new?
        workflows.mimeType = 'application/xml'
        workflows.dsLocation = File.join(Dor::Config.workflow.url,"dor/objects/#{self.pid}/workflows")
      end
    end

    def empty_datastream?(datastream)
      if datastream.new?
        true 
      elsif datastream.class.respond_to?(:xml_template)
        datastream.content.to_s.empty? or EquivalentXml.equivalent?(datastream.content, datastream.class.xml_template)
      else
        datastream.content.to_s.empty?
      end  
    end

    # Self-aware datastream builders
    def build_datastream(datastream, force = false, require=false)
      ds = datastreams[datastream]
      druid = DruidTools::Druid.new(self.pid, Dor::Config.stacks.local_workspace_root)
      filename = druid.find_metadata("#{datastream}.xml")
      if not filename.nil?
        content = File.read(filename)
        ds.content = content
        ds.ng_xml = Nokogiri::XML(content) if ds.respond_to?(:ng_xml)
        ds.save unless ds.digital_object.new?
      elsif force or empty_datastream?(ds)
        proc = "build_#{datastream}_datastream".to_sym
        if respond_to? proc
          content = self.send(proc, ds)
          ds.save unless ds.digital_object.new?
        end
      end
      if require and empty_datastream?(ds)
        raise "Required datastream #{datastream} could not be populated!"
      end
      return ds
    end

    def cleanup()
      CleanupService.cleanup(self)
    end

    def milestones
      Dor::WorkflowService.get_milestones('dor',self.pid)
    end
    def status
      current_version='1'
      begin
        current_version = self.versionMetadata.current_version_id 
      rescue
      end
      status = 0
      version = ''
      status_hash={
        0 => '',
        1 => 'Registered',
        2 => 'In accessioning',
        3 => 'In accessioning (described)',
        4 => 'In accessioning (described, published)',
        5 => 'In accessioning (described, published, deposited)',
        6 => 'Accessioned',
        7 => 'Accessioned (indexed)',
        8 => 'Accessioned (indexed, ingested)',
        9 => 'Opened'
      }           
      status_time=nil

      current=false
      versions=[]
      result=""
      milestones.each do |m|
        if m[:version]
          versions << m[:version]
        else
          current=true
        end
      end
      versions.sort
      oldest_version=versions.last
      if(oldest_version.nil?)
        oldest_version='1'
      end
      milestones.each do |m| 
        name=m[:milestone]
        time=m[:at].utc.xmlschema
        version=m[:version]
        if (current and not version) or (not current and version==oldest_version)
          case name
          when 'registered'
            if status<1
              status=1
              status_time=time
            end        
          when 'submitted'
            if status<2
              status=2
              status_time=time
            end
          when 'described'
            if status<3
              status=3
              status_time=time
            end
          when 'published'
            if status<4
              status=4
              status_time=time
            end
          when 'deposited'
            if status<5
              status=5
              status_time=time
            end
          when 'accessioned'
            if status<6
              puts version
              status=6
              status_time=time
            end
          when 'indexed'
            if status<7
              status=7
              status_time=time
            end
          when 'shelved'
            if status<8
              status=8
              status_time=time
            end
          when 'opened'
            if status<1
              status=1
              status_time=time
            end
          end
        end
      end
      if status == 1
        if (current and current_version.to_i > 1) or (not current and oldest_version.to_i > 1)
        status = 9
        end
      end
      if current
        result='v'+current_version.to_s+' '+status_hash[status].to_s
      else
        result='v'+oldest_version+' '+status_hash[status].to_s
      end
      result
    end

    def to_solr(solr_doc=Hash.new, *args)
      super(solr_doc, *args)
      sortable_milestones = {}
      current_version='1'
      begin
        current_version = self.versionMetadata.current_version_id 
      rescue
      end
      current_version_num=current_version.to_i
      if self.methods.include?('versionMetadata')
      #add an entry with version id, tag and description for each version
      while current_version_num > 0
        add_solr_value(solr_doc, 'versions', current_version_num.to_s + ';' + self.versionMetadata.tag_for_version(current_version_num.to_s) + ';' + self.versionMetadata.description_for_version(current_version_num.to_s), :string, [:displayable])
        current_version_num -= 1
      end
    end
      self.milestones.each do |milestone|
        timestamp = milestone[:at].utc.xmlschema
        sortable_milestones[milestone[:milestone]] ||= []
        sortable_milestones[milestone[:milestone]] << timestamp
        add_solr_value(solr_doc, 'lifecycle', milestone[:milestone], :string, [:searchable, :facetable])
        if(not milestone[:version])
          milestone[:version]=current_version
        end
        add_solr_value(solr_doc, 'lifecycle', "#{milestone[:milestone]}:#{timestamp};#{milestone[:version]}", :string, [:displayable])
      end

      sortable_milestones.each do |milestone, unordered_dates|
        dates = unordered_dates.sort
        #create the published_dt and published_day fields and the like
        add_solr_value(solr_doc, milestone+'_day', DateTime.parse(dates.first).beginning_of_day.utc.xmlschema.split('T').first, :string, [:searchable, :facetable])
        add_solr_value(solr_doc, milestone, dates.first, :date, [:searchable, :facetable])

        #fields for OAI havester to sort on
        add_solr_value(solr_doc, "#{milestone}_earliest_dt", dates.first, :date, [:sortable])
        add_solr_value(solr_doc, "#{milestone}_latest_dt", dates.last, :date, [:sortable])

        #for future faceting
        add_solr_value(solr_doc, "#{milestone}_earliest", dates.first, :date, [:searchable, :facetable])
        add_solr_value(solr_doc, "#{milestone}_latest", dates.last, :date, [ :searchable, :facetable])

      end
      add_solr_value(solr_doc,"status",status,:string, [:displayable])
      
      if self.methods.include?('new_version_open?') and new_version_open?
        #add a facetable field for the date when the open version was opened 
        opened_date=sortable_milestones['opened'].sort.last
        add_solr_value(solr_doc, "version_opened", DateTime.parse(opened_date).beginning_of_day.utc.xmlschema.split('T').first, :string, [ :searchable, :facetable])
      end
      add_solr_value(solr_doc, "current_version", current_version.to_s, :string, [ :displayable , :facetable])
      add_solr_value(solr_doc, "last_modified_day", self.modified_date.to_s.split('T').first, :string, [ :facetable ])
      solr_doc
    end

    # Initilizes workflow for the object in the workflow service
    # @param [String] name of the workflow to be initialized
    # @param [String] repo name of the repository to create workflow for
    # @param [Boolean] create_ds create a 'workflows' datastream in Fedora for the object
    def initialize_workflow(name, repo='dor', create_ds=true)
      Dor::WorkflowService.create_workflow(repo, self.pid, name, Dor::WorkflowObject.initial_workflow(name), :create_ds => create_ds)
    end
  end
end

