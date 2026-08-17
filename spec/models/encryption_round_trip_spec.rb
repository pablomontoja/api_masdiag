require "rails_helper"

# Guards field-level encryption across a language runtime change.
#
# ApiAccount#settings is Lockbox-encrypted (`has_encrypted :settings, type: :hash`)
# and holds per-account configuration. Lockbox 2.2.0 was verified against Active
# Record 7.2.3 on Ruby 3.3.7; raising the runtime replaces the host for its
# cryptographic operations, so the round trip is re-asserted rather than assumed.
#
# This spec proves same-runtime correctness. Cross-runtime correctness — data
# written on 3.3.7 and read on 3.4.10 — cannot be expressed in the suite, because
# each run happens on a single runtime. That is verified separately against a
# persisted probe record (see specs/008-ruby-34-upgrade/baseline.md).
#
# See specs/008-ruby-34-upgrade — US2, FR-011, SC-010.
RSpec.describe "ApiAccount encrypted settings", type: :model do
  let!(:institution) { create(:institution, id: 1) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id) }
  let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

  let(:secret) { "round-trip-canary" }

  it "round-trips a hash value through encryption" do
    api_account.settings = { probe: secret, nested: { level: 2 } }
    api_account.save!

    reloaded = ApiAccount.find(api_account.id)

    expect(reloaded.settings[:probe]).to eq(secret)
    expect(reloaded.settings[:nested][:level]).to eq(2)
  end

  it "never stores the plaintext in the ciphertext column" do
    api_account.settings = { probe: secret }
    api_account.save!

    ciphertext = ApiAccount.find(api_account.id).settings_ciphertext.to_s

    expect(ciphertext).to be_present
    expect(ciphertext).not_to include(secret)
  end

  it "reads back a value written by a separate model instance" do
    api_account.settings = { probe: secret }
    api_account.save!

    # A fresh instance decrypts from the database rather than from memory,
    # which is the path that a runtime change could plausibly affect.
    expect(ApiAccount.find(api_account.id).settings).to eq({ probe: secret })
  end
end
