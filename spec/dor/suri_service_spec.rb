require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Dor::SuriService do
  
  before(:all) do
    with_warnings_suppressed do
      Dor::MINT_SURI_IDS = true
      Dor::SURI_URL = 'http://some.suri.host:8080'
      Dor::ID_NAMESPACE = 'druid'
      Dor::SURI_USER = 'suriuser'
      Dor::SURI_PASSWORD = 'suripword'
    end
  end

  before(:each) do
    @my_client = mock('restclient')
    RestClient::Resource.stub!(:new).and_return(@my_client)
  end
  
  # it "should mint a druid" do
  #   id = Dor::SuriService.mint_id
  #   puts id
  #   id.should_not be_nil
  #   id.should =~ /^druid:/
  # end
  describe "an enabled SuriService" do
        
    it "should mint a druid using RestClient::Resource" do
      @my_client.should_receive(:post).with("").and_return('somestring')
      
      Dor::SuriService.mint_id.should == "#{Dor::ID_NAMESPACE}:somestring"                                         
    end
  
    it "should throw log an error and rethrow the exception if Connect fails." do
      e = "thrown exception"
      ex = Exception.new(e)
      
      @my_client.should_receive(:post).with("").and_raise(ex)
                                                
      lambda{ Dor::SuriService.mint_id }.should raise_error(Exception, "thrown exception")
    end
    
  end
  
  it "should use the Fedora->nextpid service if calls to SURI are disabled" do
    with_warnings_suppressed{Dor::MINT_SURI_IDS = false}
    Fedora::Repository.stub_chain(:instance, :nextid).and_return('pid:123')
    
    Dor::SuriService.mint_id.should == 'pid:123'
  end
  
  # it "should mint a real id in an integration test" do
  #   with_warnings_suppressed do
  #     MINT_SURI_IDS = true
  #     ID_NAMESPACE = 'druid'
  #     SURI_URL = 'http://lyberservices-test.stanford.edu:8080'
  #     SURI_USER = 'hydra-etd'
  #     SURI_PASSWORD = 'lyberteam'
  #   end
  #   
  #    Dor::SuriService.mint_id.should == ''
  # end
  
end