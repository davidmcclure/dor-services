require 'rest-client'

module Dor
  
  # Methods to create and update workflow
  #
  # ==== Required Constants
  # - Dor::CREATE_WORKFLOW : true or false.  Can be used to turn of workflow in a particular environment, like development
  # - Dor::WF_URI : The URI to the workflow service.  An example URI is 'http://lyberservices-dev.stanford.edu/workflow'
  module WorkflowService

    Config.declare(:workflow) { url nil }
  
    class << self
      # Creates a workflow for a given object in the repository.  If this particular workflow for this objects exists,
      # it will replace the old workflow with wf_xml passed to this method.     
      # Returns true on success.  Caller must handle any exceptions
      #
      # == Parameters
      # - <b>repo</b> - The repository the object resides in.  The service recoginzes "dor" and "sdr" at the moment
      # - <b>druid</b> - The id of the object
      # - <b>workflow_name</b> - The name of the workflow you want to create
      # - <b>wf_xml</b> - The xml that represents the workflow
      # 
      def create_workflow(repo, druid, workflow_name, wf_xml)
        workflow_resource["#{repo}/objects/#{druid}/workflows/#{workflow_name}"].put(wf_xml, :content_type => 'application/xml')
        return true
      end
  
      # Updates the status of one step in a workflow.      
      # Returns true on success.  Caller must handle any exceptions
      #
      # == Required Parameters
      # - <b>repo</b> - The repository the object resides in.  The service recoginzes "dor" and "sdr" at the moment
      # - <b>druid</b> - The id of the object
      # - <b>workflow_name</b> - The name of the workflow 
      # - <b>status</b> - The status that you want to set.  Typical statuses are 'waiting', 'completed', 'error', but could be any string
      # 
      # == Optional Parameters
      # - <b>elapsed</b> - The number of seconds it took to complete this step. Can have a decimal.  Is set to 0 if not passed in.
      # - <b>lifecycle</b> - Bookeeping label for this particular workflow step.  Examples are: 'registered', 'shelved'
      #
      # == Http Call
      # The method does an HTTP PUT to the URL defined in Dor::WF_URI.  As an example:
      #   PUT "/dor/objects/pid:123/workflows/GoogleScannedWF/convert"
      #   <process name=\"convert\" status=\"completed\" />"
      def update_workflow_status(repo, druid, workflow, process, status, elapsed = 0, lifecycle = nil)
        xml = create_process_xml(:name => process, :status => status, :elapsed => elapsed.to_s, :lifecycle => lifecycle)
        workflow_resource["#{repo}/objects/#{druid}/workflows/#{workflow}/#{process}"].put(xml, :content_type => 'application/xml')
        return true
      end
  
      #
      # Retrieves the process status of the given workflow for the given object identifier
      #
      def get_workflow_status(repo, druid, workflow, process)
        workflow_md = workflow_resource["#{repo}/objects/#{druid}/workflows/#{workflow}"].get
        doc = Nokogiri::XML(workflow_md)
        raise Exception.new("Unable to parse response:\n#{workflow_md}") if(doc.root.nil?)
    
        status = doc.root.at_xpath("//process[@name='#{process}']/@status").content
        return status
      end
  
      def get_workflow_xml(repo, druid, workflow)
        workflow_resource["#{repo}/objects/#{druid}/workflows/#{workflow}"].get
      end    

      # Updates the status of one step in a workflow to error.      
      # Returns true on success.  Caller must handle any exceptions
      #
      # == Required Parameters
      # - <b>repo</b> - The repository the object resides in.  The service recoginzes "dor" and "sdr" at the moment
      # - <b>druid</b> - The id of the object
      # - <b>workflow_name</b> - The name of the workflow 
      # - <b>error_msg</b> - The error message.  Ideally, this is a brief message describing the error
      # 
      # == Optional Parameters
      # - <b>error_txt</b> - A slot to hold more information about the error, like a full stacktrace
      #
      # == Http Call
      # The method does an HTTP PUT to the URL defined in Dor::WF_URI.  As an example:
      #   PUT "/dor/objects/pid:123/workflows/GoogleScannedWF/convert"
      #   <process name=\"convert\" status=\"error\" />"
      def update_workflow_error_status(repo, druid, workflow, process, error_msg, error_txt = nil)
        xml = create_process_xml(:name => process, :status => 'error', :errorMessage => error_msg, :errorText => error_txt)
        workflow_resource["#{repo}/objects/#{druid}/workflows/#{workflow}/#{process}"].put(xml, :content_type => 'application/xml')
        return true
      end
      
#      private
      def create_process_xml(params)
        builder = Nokogiri::XML::Builder.new do |xml|
          attrs = params.reject { |k,v| v.nil? }
          xml.process(attrs)
        end
        return builder.to_xml
      end
      
      def workflow_resource
        RestClient::Resource.new(Config.workflow.url,
        :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read(Config.fedora.cert_file)),
        :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read(Config.fedora.key_file), Config.fedora.key_pass))
      end
    end
  end
end
