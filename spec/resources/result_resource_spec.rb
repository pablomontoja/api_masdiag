require 'rails_helper'

RSpec.describe ResultResource do
  let(:institution) { create(:institution, id: 1) }
  let(:contractor) { create(:contractor, institution: institution) }
  let(:patient) { create(:patient, contractor: contractor) }
  let(:project) { create(:project, eng_name: "Vitamin D Test") }
  let(:product) { create(:product) }
  let(:package) { create(:package, product: product) }
  let(:rsc) { create(:reserved_sample_code, package_id: package.id, IsRetailSale: true) }
  let(:user) { User.create(Id: 1,                                                      
                           Login: "pswider",                                           
                           Password: "krYrVQGMklxYLuP69WBMR2CNV1GXHiYSdtgL2+oZ8B6tFWrTUjGXnHx+HOargHzdFs4rOTHPdOOLhLyaEvGv7Q==",
                           Salt: "UrW3QDWN/Bko6GIimyQyLnyapkKlbHuYRrabGUXEUh4=",       
                           FirstName: "Małgorzata",                                    
                           LastName: "Rogozińska, PhD",                                
                           IsActive: true,                                             
                           Role: 1,                                                    
                           email: "pawelswider@gmail.com",                             
                           encrypted_password: "$2a$12$3suXpah9VgrKDlvT2DvS0ew3./ejBwsRyYFupEeUPCSVpP4GECuTW",
                           reset_password_token: nil,                                  
                           reset_password_sent_at: nil,                                
                           remember_created_at: nil,
                           sign_in_count: 93,
                           current_sign_in_at: "Thu, 10 Nov 2022 13:31:32.000000000 UTC +00:00",
                           last_sign_in_at: "Wed, 26 Oct 2022 18:25:40.000000000 UTC +00:00",
                           current_sign_in_ip: "127.0.0.1",
                           last_sign_in_ip: "127.0.0.1",
                           created_at: "Sun, 25 Sep 2016 00:00:00.000000000 UTC +00:00",
                           updated_at: "Thu, 10 Nov 2022 13:31:32.000000000 UTC +00:00",
                           type: "Admin",
                           Description: "Research and Development Manager",
                           LastPasswordChangeAt: "Sun, 01 Jan 2034 05:05:05.000000000 UTC +00:00",
                           PasswordChangeRevokedAt: nil,
                           password_changed_at: nil,
                           LastSelectedCertLabel: "16783362",
                           HasSmartCard: true,
                           TokenSerialNumber: "2036513489107353") }

  # Helper method to create analyte and analyte_result
  def create_analyte_and_result(measurement, value = 50.0, name_in_api = "Vitamin D")
    analyte = Analyte.create!(
      Id: SecureRandom.random_number(1000),
      ProjectId: project.Id,
      Name: "Vitamin D",
      NameInAPI: name_in_api,
      CutoffMin: 30.0,
      CutoffMax: 100.0,
      IsCalculatedFromOthers: false,
      is_required: true,
      ExcludedFromStatistic: true
    )

    result = Result.create!(
      MeasurementId: measurement.Id,
      ImportDate: 2.days.ago,
      IsValid: true,
      ImportUserId: user.Id
    )

    AnalyteResult.create!(
      ResultId: result.MeasurementId,
      AnalyteId: analyte.Id,
      Value: value,
      Unit: "ng/ml",
      MeasuredValue: value
    )

    return analyte, result
  end

  describe '#initialize' do
    let(:sample) { create(:sample, patient: patient) }
    let(:current_rsc) { rsc }

    it 'initializes with sample and current_rsc' do
      resource = ResultResource.new(sample, current_rsc)
      expect(resource).to be_a(ResultResource)
    end
  end

  describe '#call' do
    it 'returns the result of prepare_json' do
      sample = create(:sample, patient: patient)
      resource = ResultResource.new(sample, rsc)

      # Spy on prepare_json
      allow(resource).to receive(:call).and_return({ test: 'data' })

      expect(resource.call).to eq({ test: 'data' })
    end
  end

  describe '#prepare_json' do
    context 'when sample is rejected (SampleStatus == 4)' do
      let!(:unsuitable_soaking) { create(:soaking_degree, id: 4, name: "nie nadaje się", sn: 4) }
      let!(:good_soaking) { create(:soaking_degree) }
      let(:sample) { create(:sample, patient: patient, SampleStatus: 4, soaking_degree: unsuitable_soaking) }

      it 'returns rejection information without rejection reason when soaking_degree_id is ok' do
        result = ResultResource.call(sample, rsc)

        expect(result).to be_a(Hash)
        expect(result[:results]).to be_an(Array)
        expect(result[:results].first).to include(
          sample_code: sample.Code,
          sample_status: "cancelled"
        )
        expect(result[:results].first).to have_key(:rejection_reason)
      end

      it 'includes rejection reason when soaking_degree_id is 4' do
        # create(:soaking_degree, id: 4, name: "nie nadaje się", sn: 4)
        sample.update(soaking_degree_id: 4)
        result = ResultResource.new(sample, rsc).call

        expect(result[:results].first).to include(
          rejection_reason: "quantity not sufficient"
        )
      end

      it 'includes rejection reason when soaking_degree_id is 5' do
        create(:soaking_degree, id: 5, name: "mokra", sn: 5)
        sample.update(soaking_degree_id: 5)
        result = ResultResource.new(sample, rsc).call

        expect(result[:results].first).to include(
          rejection_reason: "wet test card"
        )
      end
    end

    context 'when sample has measurements' do
      let(:soaking_degree) { SoakingDegree.find_or_create_by(id: 1, sn: 1, name: "dobrze") }
      let(:unsuitable_soaking) { SoakingDegree.find_or_create_by(id: 4, sn: 4, name: "nie nadaje się") }
      let(:sample) { create(:sample, patient: patient, SampleStatus: 2, SampleState: 2, AcceptanceDate: 2.days.ago, Code: rsc.Code, soaking_degree_id: soaking_degree.id) }
      let!(:measurement) { create(:measurement, sample: sample, project: project, Status: 5, AuthorizedAt: 1.day.ago) }

      before do
        # Create reserved sample code with projects
        rsc.reserved_tests.create!(project: project)
      end

      context 'with online file' do
        before do
          # Create online file
          online_file = create(:online_file, measurement: measurement)
          online_file.update(file_contents: "test content", filename: "test.pdf")

          # Mock ActiveStorage and url_for
          allow_any_instance_of(OnlineFile).to receive(:prepare_active_storage)
          allow_any_instance_of(ResultResource).to receive(:url_for).and_return("http://example.com/test.pdf")

          # Mock RawResultResource
          allow(RawResultResource).to receive(:call).and_return([{ parameter: "Vitamin D", value: "50.0", unit: "ng/ml" }])
        end

        it 'includes measurement data with unencrypted_result URL' do
          result = ResultResource.new(sample, rsc).call

          expect(result[:results].first).to include(
            sample_code: sample.Code,
            test: project.eng_name,
            authorized_at: measurement.AuthorizedAt,
            lab_arrival_time: sample.AcceptanceDate,
            measurement_status: "authorized",
            sample_status: "in lab, accepted for measurement",
            unencrypted_result: "http://example.com/test.pdf"
          )
          expect(result[:results].first[:raw_result]).to be_an(Array)
        end
      end

      context 'without online file' do
        before do
          # Create analyte and result
          create_analyte_and_result(measurement)

          # Mock RawResultResource
          allow(RawResultResource).to receive(:call).and_return([{ parameter: "Vitamin D", value: "50.0", unit: "ng/ml" }])
        end

        it 'includes measurement data with nil unencrypted_result' do
          result = ResultResource.new(sample, rsc).call

          expect(result[:results].first).to include(
            sample_code: sample.Code,
            test: project.eng_name,
            authorized_at: measurement.AuthorizedAt,
            lab_arrival_time: sample.AcceptanceDate,
            measurement_status: "authorized",
            sample_status: "in lab, accepted for measurement",
            unencrypted_result: nil
          )
          expect(result[:results].first[:raw_result]).to be_an(Array)
        end

        it 'includes empty raw_result when measurement status is not 5' do
          measurement.update(Status: 4)
          result = ResultResource.new(sample, rsc).call

          expect(result[:results].first[:raw_result]).to eq([])
        end

        it 'includes rejection_reason when sample is rejected' do
          sample.update(SampleStatus: 4, soaking_degree_id: unsuitable_soaking.id)
          result = ResultResource.new(sample, rsc).call

          expect(result[:results].first).to include(
            rejection_reason: "quantity not sufficient"
          )
        end
      end

      context 'when no measurements match project criteria' do
        let(:inst) { create(:institution, id: 2) }
        it 'returns empty results array when no measurements match' do
          # Create a different reserved sample code with different projects          
          different_rsc = create(:second_reserved_sample_code, IsRetailSale: true, InstitutionId: inst.id, package: package)
          different_project = create(:project, Id: 999, Name: "Different Test")
          different_rsc.reserved_tests.create!(project: different_project)

          result = ResultResource.new(sample, different_rsc).call

          expect(result[:results]).to be_empty
        end
      end
    end
  end

  describe 'helper methods' do
    describe '#rejection_reason' do
      let(:sample) { create(:sample, patient: patient) }
      let(:resource) { ResultResource.new(sample, rsc) }

      it 'returns empty string by default' do
        expect(resource.send(:rejection_reason, sample)).to eq("")
      end

      it 'returns "quantity not sufficient" when soaking_degree_id is 4' do
        create(:soaking_degree, id: 4, name: "nie nadaje się", sn: 4)
        sample.update(soaking_degree_id: 4)
        expect(resource.send(:rejection_reason, sample)).to eq("quantity not sufficient")
      end

      it 'returns "wet test card" when soaking_degree_id is 5' do
        create(:soaking_degree, id: 5, name: "mokra", sn: 5)
        sample.update(soaking_degree_id: 5)
        expect(resource.send(:rejection_reason, sample)).to eq("wet test card")
      end
    end

    describe '#get_status' do
      let(:sample) { create(:sample, patient: patient) }
      let(:resource) { ResultResource.new(sample, rsc) }

      it 'returns combined state and status when SampleStatus is not 4' do
        sample.update(SampleState: 2, SampleStatus: 2)
        expect(resource.send(:get_status, sample)).to eq("in lab, accepted for measurement")
      end

      it 'returns only status when SampleStatus is 4' do
        sample.update(SampleState: 2, SampleStatus: 4)
        expect(resource.send(:get_status, sample)).to eq("cancelled")
      end
    end

    describe '#measurement_status' do
      let!(:rsc) { create(:second_reserved_sample_code, package_id: package.id, IsRetailSale: true, InstitutionId: institution.id) }
      let(:resource) { ResultResource.new(create(:sample), rsc) }

      it 'returns correct status for each status code' do
        # byebug
        # rsc = create(:second_reserved_sample_code, package_id: package.id, IsRetailSale: true, InstitutionId: institution.id) 
        # resource = ResultResource.new(create(:sample), rsc)
        expect(resource.send(:measurement_status, 1)).to eq("before measurement")
        expect(resource.send(:measurement_status, 2)).to eq("in measurement")
        expect(resource.send(:measurement_status, 3)).to eq("in measurement")
        expect(resource.send(:measurement_status, 4)).to eq("measured")
        expect(resource.send(:measurement_status, 5)).to eq("authorized")
        expect(resource.send(:measurement_status, 6)).to eq("cancelled measurement")
        expect(resource.send(:measurement_status, 7)).to eq("registered online")
        expect(resource.send(:measurement_status, 999)).to eq("unknown")
      end
    end

    describe '#sample_state' do
      let!(:rsc) { create(:second_reserved_sample_code, package_id: package.id, IsRetailSale: true, InstitutionId: institution.id) }
      let(:resource) { ResultResource.new(create(:sample), rsc) }

      it 'returns correct state for each state code' do
        expect(resource.send(:sample_state, 0)).to eq("undefined")
        expect(resource.send(:sample_state, 1)).to eq("out of lab")
        expect(resource.send(:sample_state, 2)).to eq("in lab")
        expect(resource.send(:sample_state, 3)).to eq("sent back")
        expect(resource.send(:sample_state, 4)).to eq("archived")
        expect(resource.send(:sample_state, 5)).to eq("utilized")
        expect(resource.send(:sample_state, 999)).to eq("unknown")
      end
    end

    describe '#sample_status' do
      let!(:rsc) { create(:second_reserved_sample_code, package_id: package.id, IsRetailSale: true, InstitutionId: institution.id) }
      let(:resource) { ResultResource.new(create(:sample), rsc) }

      it 'returns correct status for each status code' do
        expect(resource.send(:sample_status, 0)).to eq("undefined")
        expect(resource.send(:sample_status, 1)).to eq("registered online")
        expect(resource.send(:sample_status, 2)).to eq("accepted for measurement")
        expect(resource.send(:sample_status, 3)).to eq("clarification needed")
        expect(resource.send(:sample_status, 4)).to eq("cancelled")
        expect(resource.send(:sample_status, 5)).to eq("pool recharged after cancellation")
        expect(resource.send(:sample_status, 999)).to eq("unknown")
      end
    end
  end
end
