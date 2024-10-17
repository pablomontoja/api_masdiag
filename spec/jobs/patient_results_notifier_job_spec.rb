# require 'rails_helper'

# include MasdiagMailer

# RSpec.describe PatientResultsNotifierJob, type: :job do

#   subject { described_class.new }
#   subject(:job) { described_class.perform_later() }

#   describe '#perform' do
#   	let(:contractor) { create(:contractor) }
#     let(:patient) { create(:patient, contractor: contractor) }
#     let(:sample) { create(:sample, patient: patient) }
#     let(:measurement) { create(:measurement, sample: sample) }
#     let(:online_file) { create(:online_file, measurement: measurement, is_patient_notification_send: false) }

#     let(:four_months_ago) { 4.months.ago }
#     let(:patients_ids) { [1, 2, 3] } # stubbed patient IDs
#     let(:files) { [[1, 1], [2, 2], [3, 3]] } # stubbed files with measurement ID and patient ID

#     before do
#       allow(Patient).to receive(:where).with(send_results_on_mail: true).and_return(double(pluck: patients_ids))
#       allow(OnlineFile).to receive(:includes).with(measurement: { sample: :patient }).and_return(double(where: files))
#     end

#     it 'does not send emails if no files are found' do
#       allow(files).to receive(:count).and_return(0)
#       expect(PatientResultNotificationMailer).not_to receive(:send_mail)
#       subject.perform
#     end

#     it 'sends emails for each file' do
#       files.each do |file|
#         patient_id = file[1]
#         file_id = file[0]
#         patient = double(email: 'patient@example.com', send_results_on_mail: true)
#         allow(Patient).to receive(:find).with(patient_id).and_return(patient)
#         expect(PatientResultNotificationMailer).to receive(:send_mail).with(patient_id, file_id).and_return(double(deliver_later: true))
#       end
#       subject.perform
#     end

#     it 'skips patients with blank email or without send_results_on_mail' do
#       patient = double(email: '', send_results_on_mail: false)
#       allow(Patient).to receive(:find).with(patients_ids.first).and_return(patient)
#       expect(PatientResultNotificationMailer).not_to receive(:send_mail)
#       subject.perform
#     end

#     it 'skips patients with contractor API account' do
#       patient = double(email: 'patient@example.com', send_results_on_mail: true, contractor: double(api_account: true))
#       allow(Patient).to receive(:find).with(patients_ids.first).and_return(patient)
#       expect(PatientResultNotificationMailer).not_to receive(:send_mail)
#       subject.perform
#     end

#     it 'skips patients with contractor institution kind "Hospital" and institution ID not 69' do
#       patient = double(email: 'patient@example.com', send_results_on_mail: true, contractor: double(institution: double(kind: 'Hospital', id: 70)))
#       allow(Patient).to receive(:find).with(patients_ids.first).and_return(patient)
#       expect(PatientResultNotificationMailer).not_to receive(:send_mail)
#       subject.perform
#     end
#   end
# end