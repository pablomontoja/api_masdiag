require 'rails_helper'

RSpec.describe MasdiagMailer::SendNotificationAfterDelayedRegJob, type: :job do
  describe '#perform' do
    let(:sample_id) { 123 }
    let(:project1) { create(:project, responsible_person_email: 'person1@example.com') }
    let(:project2) { create(:project, responsible_person_email: 'person2@example.com', Id: 10) }
    let(:sample) { create(:sample, Id: sample_id, AcceptanceDate: 2.days.ago) }
    
    let!(:measurement1) { create(:measurement, Id: 1, project: project1, sample: sample) }
    let!(:measurement2) { create(:measurement, Id: 2, project: project1, sample: sample) }
    let!(:measurement3) { create(:measurement, Id: 3, project: project2, sample: sample) }

    before do
      allow(MasdiagMailer::SendNotificationAfterDelayedRegMailer).to receive(:send_mail).and_return(double(deliver_later: true))
    end

    it 'groups measurements by project responsible person email' do
      subject.perform(sample_id)

      expect(MasdiagMailer::SendNotificationAfterDelayedRegMailer).to have_received(:send_mail)
        .with('person1@example.com', [1, 2])
      expect(MasdiagMailer::SendNotificationAfterDelayedRegMailer).to have_received(:send_mail)
        .with('person2@example.com', [3])
    end

    context 'when there are no measurements for the sample' do
      before do
        allow(Measurement).to receive(:joins).and_return(Measurement.none)
      end

      it 'does not send any emails' do
        subject.perform(sample_id)
        expect(MasdiagMailer::SendNotificationAfterDelayedRegMailer).not_to have_received(:send_mail)
      end
    end

    context 'when sample_id is invalid' do
      let(:invalid_sample_id) { -1 }

      it 'does not send any emails' do
        subject.perform(invalid_sample_id)
        expect(MasdiagMailer::SendNotificationAfterDelayedRegMailer).not_to have_received(:send_mail)
      end
    end
  end
end