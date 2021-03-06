require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Dor::Configuration do
  
  before :each do
    @config = Dor::Configuration.new(YAML.load(File.read(File.expand_path('../../../config/config_defaults.yml', __FILE__))))
  end
  
  it "should issue a deprecation warning if SSL options are passed to the fedora block" do
    ActiveSupport::Deprecation.should_receive(:warn).with(/fedora.cert_file/, instance_of(Array))
    ActiveSupport::Deprecation.should_receive(:warn).with(/fedora.key_file/, instance_of(Array))
    @config.configure do
      fedora do
        cert_file 'my_cert_file'
        key_file 'my_key_file'
      end
    end
  end

  it "should move SSL options from the fedora block to the ssl block" do
    ActiveSupport::Deprecation.silence do
      @config.configure do
        fedora do
          cert_file 'my_cert_file'
          key_file 'my_key_file'
        end
      end
    end
    @config.ssl.should == { :cert_file => 'my_cert_file', :key_file => 'my_key_file', :key_pass => '' }
    @config.fedora.has_key?(:cert_file).should == false
  end

  it "configures the Dor::WorkflowService when Dor::Config.configure is called" do
    @config.configure do
      workflow.url 'http://mynewurl.edu/workflow'
    end

    Dor::WorkflowService.workflow_resource.to_s.should == 'http://mynewurl.edu/workflow'
  end
end
