require 'rails_helper'

RSpec.describe ResultResource, type: :service do
  let(:sample) { create(:sample_with_soaking, Code: 'SAMPLE001') }
  let(:current_rsc) { create(:reserved_sample_code_with_institution, Code: 'SAMPLE001') }
  let(:project) { create(:project) }
  let(:service) { described_class.new(sample, current_rsc) }


  before do
    # Mock Rails route helpers
    allow(service).to receive(:url_for).and_return('http://example.com/file.pdf')
  end

  describe '#call' do
    context 'when sample is cancelled' do
      let(:sample) { create(:sample_with_soaking, SampleStatus: 4, Code: 'SAMPLE001') }

      it 'returns cancelled sample result' do
        result = service.call

        expect(result[:results].size).to eq(1)
        expect(result[:results].first).to include(
          sample_code: 'SAMPLE001',
          sample_status: 'cancelled',
          lab_arrival_time: sample.AcceptanceDate,
          rejection_reason: kind_of(String)
        )
      end

      context 'with insufficient quantity' do
        let!(:sd) { create(:soaking_degree, id: 4, sn: 4) }
        let(:sample) { create(:sample_with_soaking, SampleStatus: 4, soaking_degree_id: sd.id) }

        it 'includes correct rejection reason' do
          result = service.call
          
          expect(result[:results].first[:rejection_reason]).to eq('quantity not sufficient')
        end
      end

      context 'with wet test card' do
        let!(:sd) { create(:soaking_degree, id: 5, sn: 5) }
        let(:sample) { create(:sample_with_soaking, SampleStatus: 4, soaking_degree_id: sd.id) }

        it 'includes correct rejection reason' do
          result = service.call
          
          expect(result[:results].first[:rejection_reason]).to eq('wet test card')
        end
      end
    end

    context 'when sample is not cancelled' do
      let(:project) { create(:project_without_fixed_id) }
      let(:analyte) { create(:analyte, ProjectId: project.Id)}
      let(:current_rsc) { create(:reserved_sample_code_with_institution, Code: 'SAMPLE002') }
      let(:sample) { create(:sample_with_soaking, SampleStatus: 2, Code: 'SAMPLE002') }
      let!(:measurement) { create(:measurement_with_result, sample: sample, ProjectId: project.Id, Status: 5) }
      let(:db_result) { create(:result, MeasurementId: measurement.Id) }
      # let(:analyte_result) { create(:analyte_result, ResultId: db_result.MeasurementId) }

      before do
        analyte_result = create(:analyte_result, ResultId: db_result.MeasurementId, AnalyteId: analyte.Id)
        current_rsc.reserved_tests.create(project_id: analyte_result.analyte.project.Id)
        # measurement # ensure measurement is created
      end

      it 'returns measurement results' do
        result = ResultResource.call(sample, current_rsc)

        expect(result[:results].size).to eq(1)
        expect(result[:results].first).to include(
          sample_code: 'SAMPLE002',
          test: project.eng_name,
          measurement_status: 'authorized',
          sample_status: kind_of(String)
        )
      end

      # context 'with online file' do
      #   let(:online_file) { create(:online_file, file_contents: 'test content') }
      #   let(:measurement) { create(:measurement, sample: sample, project: project, Status: 5, online_file: online_file) }

      #   before do
      #     allow(online_file).to receive(:prepare_active_storage)
      #     allow(online_file).to receive(:unencrypted_result).and_return('mock_file')
      #     allow(RawResultResource).to receive(:call).with(measurement).and_return(['raw_data'])
      #   end

      #   it 'includes unencrypted result URL' do
      #     result = service.call

      #     expect(result[:results].first[:unencrypted_result]).to eq('http://example.com/file.pdf')
      #     expect(result[:results].first[:raw_result]).to eq(['raw_data'])
      #   end
      # end

      context 'without online file' do
        let(:measurement) { create(:measurement, sample: sample, project: project, Status: 5, online_file: nil) }

        before do
          allow(RawResultResource).to receive(:call).with(measurement).and_return(['raw_data'])
        end

        it 'sets unencrypted_result to nil' do
          result = service.call

          expect(result[:results].first[:unencrypted_result]).to be_nil
          expect(result[:results].first[:raw_result]).to eq(['raw_data'])
        end
      end

      context 'when measurement is not authorized' do
        let(:measurement) { create(:measurement, sample: sample, project: project, Status: 4) }

        before do
          allow(RawResultResource).to receive(:call).with(measurement).and_return(['raw_data'])
        end

        it 'returns empty raw_result' do
          result = service.call

          expect(result[:results].first[:raw_result]).to eq([])
        end
      end

      context 'with multiple projects' do
        let(:project) { create(:project) }
        let(:project2) { create(:project2) }
        let(:measurement1) { create(:measurement, sample: sample, project: project, Status: 5) }
        let(:measurement2) { create(:measurement, sample: sample, project: project2, Status: 5) }

        before do
          [project, project2].each{ |pro| current_rsc.reserved_tests.create(project_id: pro.Id) }
          measurement1
          measurement2
          allow(RawResultResource).to receive(:call).and_return(['raw_data'])
        end

        it 'returns results for all projects' do
          result = service.call
          puts "----------------------------------------------"
          pp result
          puts "----------------------------------------------"

          expect(result[:results].size).to eq(2)
          expect(result[:results].map { |r| r[:test] }).to contain_exactly(project.eng_name, project2.eng_name)
        end
      end

      context 'when no measurements exist for project' do
        let(:sample) { create(:sample, Code: 'SAMPLE001') }
        let(:current_rsc) { create(:reserved_sample_code_with_institution, Code: 'SAMPLE001') }

        before do
          current_rsc.reserved_tests.find_or_create_by(project_id: project.Id)
        end

        it 'returns empty results' do
          sample.measurements.each { |m| m.result.destroy  }
          sample.measurements.destroy_all
          result = described_class.new(sample, current_rsc).call

          expect(result[:results]).to be_empty
        end
      end
    end

    context 'when current_rsc is nil' do
      let(:service) { described_class.new(sample, nil) }

      it 'returns empty results' do
        result = service.call

        expect(result[:results]).to be_empty
      end
    end
  end

  describe 'private methods' do
    describe '#measurement_status' do
      it 'returns correct status mappings' do
        expect(service.send(:measurement_status, 1)).to eq('before measurement')
        expect(service.send(:measurement_status, 2)).to eq('in measurement')
        expect(service.send(:measurement_status, 3)).to eq('in measurement')
        expect(service.send(:measurement_status, 4)).to eq('measured')
        expect(service.send(:measurement_status, 5)).to eq('authorized')
        expect(service.send(:measurement_status, 6)).to eq('cancelled measurement')
        expect(service.send(:measurement_status, 7)).to eq('registered online')
        expect(service.send(:measurement_status, 999)).to eq('unknown')
      end
    end

    describe '#sample_state' do
      it 'returns correct state mappings' do
        expect(service.send(:sample_state, 0)).to eq('undefined')
        expect(service.send(:sample_state, 1)).to eq('out of lab')
        expect(service.send(:sample_state, 2)).to eq('in lab')
        expect(service.send(:sample_state, 3)).to eq('sent back')
        expect(service.send(:sample_state, 4)).to eq('archived')
        expect(service.send(:sample_state, 5)).to eq('utilized')
        expect(service.send(:sample_state, 999)).to eq('unknown')
      end
    end

    describe '#sample_status' do
      it 'returns correct status mappings' do
        expect(service.send(:sample_status, 0)).to eq('undefined')
        expect(service.send(:sample_status, 1)).to eq('registered online')
        expect(service.send(:sample_status, 2)).to eq('accepted for measurement')
        expect(service.send(:sample_status, 3)).to eq('clarification needed')
        expect(service.send(:sample_status, 4)).to eq('cancelled')
        expect(service.send(:sample_status, 5)).to eq('pool recharged after cancellation')
        expect(service.send(:sample_status, 999)).to eq('unknown')
      end
    end

    describe '#format_sample_status' do
      context 'when sample is cancelled' do
        let(:sample) { create(:sample_with_soaking, SampleStatus: 4) }

        it 'returns only sample status' do
          result = service.send(:format_sample_status, sample)
          expect(result).to eq('cancelled')
        end
      end

      context 'when sample is not cancelled' do
        let(:sample) { create(:sample_with_soaking, SampleStatus: 2, SampleState: 2) }

        it 'returns combined state and status' do
          result = service.send(:format_sample_status, sample)
          expect(result).to eq('in lab, accepted for measurement')
        end
      end
    end

    describe '#rejection_reason' do
      let!(:sd) { create(:soaking_degree, id: 1, sn: 1) }
      let!(:sd4) { create(:soaking_degree, id: 4, sn: 4) }
      let!(:sd5) { create(:soaking_degree, id: 5, sn: 5) }
      let(:sample_insufficient) { create(:sample_with_soaking, soaking_degree_id: sd4.id, Code: Faker::Alphanumeric.alpha(number: 5)) }
      let(:sample_wet) { create(:sample_with_soaking, soaking_degree_id: sd5.id, Code: Faker::Alphanumeric.alpha(number: 5)) }
      let(:sample_other) { create(:sample_with_soaking, soaking_degree_id: sd.id, Code: Faker::Alphanumeric.alpha(number: 5)) }

      it 'returns correct rejection reasons' do
        expect(service.send(:rejection_reason, sample_insufficient)).to eq('quantity not sufficient')
        expect(service.send(:rejection_reason, sample_wet)).to eq('wet test card')
        expect(service.send(:rejection_reason, sample_other)).to eq('')
      end


    end
  end
end