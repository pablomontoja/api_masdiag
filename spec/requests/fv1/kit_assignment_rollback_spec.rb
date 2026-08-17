require 'rails_helper'

# The kit-assignment flow notifies an external partner (Lalen / FFTB,
# institution 83) that tests have been assigned to a kit. That notification
# must never be sent on the basis of a database write that did not commit:
# LalenApi::AssignKitTestsJob retries up to 10 times and there is no
# compensating action to withdraw a notification once sent.
#
# See specs/007-rails-72-upgrade — US3, FR-013, FR-014, FR-016, SC-006.
RSpec.describe 'Fv1::KitController#assign_tests partner notification timing', type: :request do
  # Institution 83 is Food For The Brain, the only institution that reaches
  # the Lalen notification branch (see Fv1::KitController#assign_tests_in_lalen_api).
  let(:fftb_institution_id) { 83 }

  let!(:project_vitd)   { create(:project, Id: 22) }
  let!(:product)        { create(:product) }
  let!(:package)        { create(:package, product: product) }
  let!(:institution)    { create(:institution, id: fftb_institution_id, name: "Food For The Brain") }
  # Institution#api_contractor_id looks up a contractor whose first_name starts with "API".
  let!(:api_contractor) { create(:contractor, institution_id: institution.id, first_name: "API") }
  let!(:api_account)    { create(:api_account, contractor_id: api_contractor.Id) }
  let!(:rsc) do
    create(:reserved_sample_code,
           package_id: package.id,
           InstitutionId: institution.id,
           IsRetailSale: true)
  end

  # Test id 22 (Vitamin D) is present in LALEN_TEST_API_KEYS, so the
  # notification branch is reached rather than short-circuited.
  let(:assign_params) { { data: { code: rsc.Code, test_ids: [22] } } }

  before { ActiveJob::Base.queue_adapter = :test }

  describe 'when the surrounding transaction commits' do
    it 'notifies the partner exactly once' do
      expect {
        post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
      }.to change {
        ActiveJob::Base.queue_adapter.enqueued_jobs
                       .count { |j| j[:job] == LalenApi::AssignKitTestsJob }
      }.by(1)

      expect(response).to have_http_status(204)
    end
  end

  describe 'when the surrounding transaction rolls back' do
    before do
      # Fail the last write inside the transaction. Before the fix the partner
      # notification was enqueued *after* this write but still inside the
      # transaction block, so a failure here rolled back the data while the
      # notification survived. After the fix the notification sits outside the
      # block and is never reached when the transaction fails.
      allow_any_instance_of(ReservedSampleCode)
        .to receive(:update!)
        .and_raise(ActiveRecord::StatementInvalid, "simulated write failure")
    end

    it 'does not notify the partner' do
      expect {
        begin
          post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
        rescue ActiveRecord::StatementInvalid
          # The controller does not rescue this; the transaction rolls back.
        end
      }.not_to change {
        ActiveJob::Base.queue_adapter.enqueued_jobs
                       .count { |j| j[:job] == LalenApi::AssignKitTestsJob }
      }
    end

    it 'does not persist the assignment' do
      begin
        post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
      rescue ActiveRecord::StatementInvalid
        # expected
      end

      expect(rsc.reload.reserved_tests).to be_empty
    end
  end

  # Structural regression guard.
  #
  # The examples above fail a write *inside* the transaction, which
  # short-circuits before the notification is reached — they pass both before
  # and after the fix, so they cannot distinguish the two arrangements. The
  # distinguishing case (a failure at commit time, after the notification was
  # enqueued but before the data landed) cannot be reproduced in the request
  # suite: `use_transactional_fixtures` wraps each example in its own
  # transaction, so the controller's `transaction` block is a savepoint and
  # never issues a real COMMIT to intercept.
  #
  # This asserts the property directly instead: the notification must not be
  # enqueued while a transaction is still open. It fails if the call is ever
  # moved back inside the transaction block.
  describe 'ordering relative to the transaction' do
    it 'enqueues the notification only after the transaction has closed' do
      open_transactions_at_enqueue = nil

      allow(LalenApi::AssignKitTestsJob)
        .to receive(:perform_later)
        .and_wrap_original do |original, *args|
          open_transactions_at_enqueue =
            ActiveRecord::Base.connection.open_transactions
          original.call(*args)
        end

      post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header

      expect(response).to have_http_status(204)
      expect(open_transactions_at_enqueue).not_to be_nil,
        "the partner notification was never enqueued — check the test setup"

      # The suite itself holds one transaction open (use_transactional_fixtures),
      # so the controller's own transaction being closed means exactly one.
      expect(open_transactions_at_enqueue).to eq(1),
        "expected the notification to be enqueued outside the assignment " \
        "transaction, but #{open_transactions_at_enqueue} transactions were open"
    end
  end
end
