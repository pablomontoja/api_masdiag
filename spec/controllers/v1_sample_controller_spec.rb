require 'rails_helper'

RSpec.describe V1::SampleController, type: :controller do

  describe 'controller tests - POST #create' do
  	context "with normal sample" do

	  	let!(:product) { create(:product) }
	    let!(:project) { create(:project) }
	    let!(:package) { create(:package, product: product) }
	    let!(:inst) { create(:institution) }
	    let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
	    let!(:contractor) {create(:contractor, institution_id: inst.id)}
	  	let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
	  	let(:smp_params) { build(:sample_with_pesel)}
	  	let!(:patient) { create(:patient, ContractorId: contractor.Id) }

	    before :each do
	    	http_login
	      rsc.reserved_tests.create!(project_id: 2)
	      rsc.update(IsRetailSale: true, InstitutionId: inst.id)
	    end

	    it 'creates a sample with proper attributes modifications' do
	      post :create, params: smp_params

	      expect(Sample.count).to eql(1)
	      expect(assigns(:sample).RegistrationDate).not_to eql(nil)
	      expect(assigns(:sample).IsWrongRegistration).to eql(false)
	      expect(assigns(:sample).WasWrongRegistration).to eql(false)
	      expect(assigns(:sample).SampleState).to eql(1)
	      expect(assigns(:sample).SampleStatus).to eql(1)
	      expect(assigns(:sample).MaterialType).to eql("dbs")
	      expect(assigns(:sample).WrongRegistrationStatus).to eql(0)
	      expect(assigns(:sample).measurements.count).to eql(1)
	      expect(assigns(:sample).measurements.pluck(:Status)).to eql([7])
	    end

	    it 'use SampleCreator to update sample' do
	    	expect(V1::WrongSampleUpdater).not_to receive(:call).and_call_original
	      expect(V1::SampleCreator).to receive(:call).and_call_original
	      post :create, params: smp_params
	    end

	    it 'use persisted patient when PESEL exist in DB' do
	      post :create, params: smp_params
	      expect(assigns(:sample).patient.Id).to eql(patient.Id)
	    end
	  end

	  context "with wrongsample" do
	  	let!(:product) { create(:product) }
	    let!(:project) { create(:project) }
	    let!(:package) { create(:package, product: product) }
	    let!(:inst) { create(:institution) }
	    let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
	    let!(:contractor) {create(:contractor, institution_id: inst.id)}
	  	let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
	  	let(:smp_params) { build(:sample_with_pesel)}
	  	let!(:patient) { create(:patient, ContractorId: contractor.Id) }
	  	let!(:sample) { create(:sample, IsWrongRegistration: true) }
	  	

	    before :each do
	    	http_login
	      rsc.reserved_tests.create!(project_id: 2)
	      rsc.update(IsRetailSale: true, InstitutionId: inst.id)
	    end

	    it 'update sample' do
	      post :create, params: smp_params

	      expect(Sample.count).to eql(1)
	      expect(assigns(:sample).RegistrationDate).not_to eql(nil)
	      expect(assigns(:sample).IsWrongRegistration).to eql(false)
	      expect(assigns(:sample).WasWrongRegistration).to eql(true)
	      expect(assigns(:sample).WrongRegistrationStatus).to eql(2)
	      expect(assigns(:sample).measurements.count).to eql(1)
	      expect(assigns(:sample).WrongRegistrationStatus).to be_in([2, 4])
	    end

	    it 'use WrongSampleUpdater to update sample' do
	    	expect(V1::WrongSampleUpdater).to receive(:call).and_call_original
	      expect(V1::SampleCreator).not_to receive(:call).and_call_original
	      post :create, params: smp_params
	    end

	    it 'when patient with PESEL exist' do
	      post :create, params: smp_params
	      expect(assigns(:sample).patient.Id).to eql(patient.Id)
	    end
	  end


    # context 'send alert email' do
    #   before do
    #     # @package = create(:package, product_id: @product.id)
    #     @institution = create(:institution, id: 34)
    #     @rsc = create(:reserved_sample_code, package_id: @package.id, InstitutionId: @institution.id, IsRetailSale: true)
    #     @contractor = create(:contractor, institution_id: @institution.id)
    #     session[:current_rsc_id] = @rsc.id
    #   end

    #   it 'when AQIPHARM is created' do
    #     expect{ post :create, params: @params }.to have_enqueued_job(SendMailNotificationJob).with('aqipharm_registration', Sample)
    #   end
    # end

  end

  # describe 'DELETE #logout_rsc' do
  #   it 'redirect to root_path' do
  #     delete :logout_rsc
  #     is_expected.to redirect_to(root_path)
  #     expect(session[:current_rsc_id]).to eq(nil)
  #   end
  # end


end
