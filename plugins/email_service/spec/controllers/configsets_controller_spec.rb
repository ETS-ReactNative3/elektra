require 'spec_helper'

describe EmailService::ConfigsetsController, type: :controller do
  routes { EmailService::Engine.routes }
 
  default_params = { domain_id: AuthenticationStub.domain_id,
                     project_id: AuthenticationStub.project_id }
 
  before(:all) do
    FriendlyIdEntry.find_or_create_entry(
      'Domain', nil, default_params[:domain_id], 'default'
    )
    FriendlyIdEntry.find_or_create_entry(
      'Project', default_params[:domain_id], default_params[:project_id],
      default_params[:project_id]
    )
  end
 

  # check index route
  describe "GET 'index'" do
    before :each do
      allow_any_instance_of(EmailService::ConfigsetsController).to receive(:list_configsets).and_return(double('config_sets').as_null_object)            
      allow_any_instance_of(EmailService::ConfigsetsController).to receive(:get_ec2_creds).and_return(double('creds').as_null_object)
    end
 
    context 'email_admin' do
      before :each do
        stub_authentication do |token|
          token['roles'] = []
          token['roles'] << { 'id' => 'email_service_role', 'name' => 'email_admin' }
          token['roles'] << { 'id' => 'cloud_support_tools_viewer_role', 'name' => 'cloud_support_tools_viewer' }         
          token
        end
      end
      it 'returns http success' do
        get :index, params: default_params
        expect(response).to be_successful
      end
    end

    context 'email_user' do
      before :each do
        stub_authentication do |token|
          token['roles'] = []
          token['roles'] << { 'id' => 'email_service_role', 'name' => 'email_user' }
          token['roles'] << { 'id' => 'cloud_support_tools_viewer_role', 'name' => 'cloud_support_tools_viewer' }         
          token
        end
      end
      it 'returns http success' do
        get :index, params: default_params
        expect(response).to be_successful
      end
    end
 
    context 'with cloud_support_tools_viewer_role' do
      before :each do
        stub_authentication do |token|
          token['roles'] = []
          token['roles'] << { 'id' => 'cloud_support_tools_viewer_role', 'name' => 'cloud_support_tools_viewer' }         
          token
        end
      end
      it 'returns http status 401' do
        get :index, params: default_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

  end

end
