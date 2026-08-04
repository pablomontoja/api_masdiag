require "rails_helper"

RSpec.describe "Toxo::SamplesController", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }

  def create_registered_sample(code: "TX001A", patient: toxo_patient)
    project = create(:toxo_project_igg)
    ReservedSampleCode.find_or_create_by!(Code: code, InstitutionId: patient.contractor.institution_id) do |rsc|
      rsc.IsRetailSale = true
      rsc.CreatedAt = Time.now
      rsc.expiry_date = 1.year.since
    end
    sample = create(:toxo_sample, Code: code, patient: patient, dispatch_date: Date.today)
    Measurement.create!(SampleId: sample.Id, ProjectId: project.Id, Status: 1, MaterialType: 0, IsRepeat: false)
    sample
  end

  # ───── authentication ────────────────────────────────────────────────────────

  describe "authentication" do
    it "returns 401 when no token" do
      get "/toxo/samples"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ───── GET /toxo/samples ─────────────────────────────────────────────────────

  describe "GET /toxo/samples" do
    it "returns only samples belonging to the contractor" do
      sample = create_registered_sample

      other_contractor = create(:contractor, institution_id: institution.id)
      other_patient    = create(:toxo_patient, contractor: other_contractor)
      other_sample     = create_registered_sample(code: "TX002A", patient: other_patient)

      get "/toxo/samples", headers: bearer

      expect(response).to have_http_status(:ok)
      ids = json["data"].map { |s| s["Id"] }
      expect(ids).to include(sample.Id)
      expect(ids).not_to include(other_sample.Id)
    end

    it "includes the patient's ContractorId" do
      sample = create_registered_sample

      get "/toxo/samples", headers: bearer

      expect(response).to have_http_status(:ok)
      returned = json["data"].find { |s| s["Id"] == sample.Id }
      expect(returned["ContractorId"]).to eq(contractor.Id)
    end
  end

  # ───── GET /toxo/samples/:id ─────────────────────────────────────────────────

  describe "GET /toxo/samples/:id" do
    it "returns the sample" do
      sample = create_registered_sample

      get "/toxo/samples/#{sample.Id}", headers: bearer

      expect(response).to have_http_status(:ok)
      expect(json["Id"]).to eq(sample.Id)
      expect(json["measurements"]).to be_an(Array)
    end

    it "returns 404 for non-existent sample" do
      get "/toxo/samples/999999", headers: bearer
      expect(response).to have_http_status(:not_found)
    end

    it "is reachable even when the sample has no measurement in the TOXO project set (matches index visibility)" do
      ReservedSampleCode.find_or_create_by!(Code: "TX003A", InstitutionId: institution.id) do |rsc|
        rsc.IsRetailSale = true
        rsc.CreatedAt = Time.now
        rsc.expiry_date = 1.year.since
      end
      sample = create(:toxo_sample, Code: "TX003A", patient: toxo_patient, dispatch_date: Date.today)
      # No measurements created — mirrors a sample visible via GET /toxo/samples (policy_scope only checks ownership)
      # but previously invisible to GET /toxo/samples/:id due to an extra ProjectId join in set_sample.

      get "/toxo/samples/#{sample.Id}", headers: bearer

      expect(response).to have_http_status(:ok)
      expect(json["Id"]).to eq(sample.Id)
    end
  end

  # ───── PUT /toxo/samples/:id ─────────────────────────────────────────────────

  describe "PUT /toxo/samples/:id" do
    def edit_params(sample, overrides = {})
      { Lot: sample.Lot, Level: sample.Level, dispatch_date: sample.dispatch_date&.to_date&.to_s }.merge(overrides)
    end

    it "updates Lot, Level, sample_collection_date, dispatch_date, and appends a note" do
      sample = create_registered_sample

      put "/toxo/samples/#{sample.Id}", params: edit_params(sample,
        Lot: "NEWLOT01",
        Level: "NEWLVL",
        sample_collection_date: 2.days.ago.to_date.to_s,
        dispatch_date: 1.day.ago.to_date.to_s,
        note: "Updated via edit form"
      ), headers: bearer

      expect(response).to have_http_status(:ok)
      expect(json["Lot"]).to eq("NEWLOT01")
      expect(json["Level"]).to eq("NEWLVL")
      expect(json["Comment"]).to include("Updated via edit form")
    end

    it "leaves fields outside the allowed 5 unchanged" do
      sample = create_registered_sample
      original_code          = sample.Code
      original_material_type = sample.MaterialType_before_type_cast
      original_status        = sample.SampleStatus

      put "/toxo/samples/#{sample.Id}", params: edit_params(sample, Lot: "NEWLOT01"), headers: bearer

      expect(response).to have_http_status(:ok)
      sample.reload
      expect(sample.Code).to eq(original_code)
      expect(sample.MaterialType_before_type_cast).to eq(original_material_type)
      expect(sample.SampleStatus).to eq(original_status)
    end

    it "silently ignores unpermitted fields in the payload" do
      sample = create_registered_sample

      put "/toxo/samples/#{sample.Id}", params: edit_params(sample,
        Lot: "NEWLOT01",
        Code: "HACKED1",
        SampleStatus: 3
      ), headers: bearer

      expect(response).to have_http_status(:ok)
      sample.reload
      expect(sample.Code).not_to eq("HACKED1")
      expect(sample.SampleStatus).not_to eq(3)
    end

    it "returns 422 when Lot is blank" do
      sample = create_registered_sample

      put "/toxo/samples/#{sample.Id}", params: edit_params(sample, Lot: ""), headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("Lot")
      expect(json["error_full_messages"]).to be_an(Array)
    end

    it "returns 422 when dispatch_date is blank" do
      sample = create_registered_sample

      put "/toxo/samples/#{sample.Id}", params: edit_params(sample, dispatch_date: ""), headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("dispatch_date")
    end

    it "returns 422 when Lot exceeds 20 characters" do
      sample = create_registered_sample

      put "/toxo/samples/#{sample.Id}", params: edit_params(sample, Lot: "L" * 21), headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("Lot")
    end

    it "returns 422 when Level exceeds 20 characters" do
      sample = create_registered_sample

      put "/toxo/samples/#{sample.Id}", params: edit_params(sample, Level: "L" * 21), headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("Level")
    end

    it "returns 403 when sample belongs to another contractor" do
      other_contractor = create(:contractor, institution_id: institution.id)
      other_patient    = create(:toxo_patient, contractor: other_contractor)
      other_sample     = create_registered_sample(code: "TX002A", patient: other_patient)

      put "/toxo/samples/#{other_sample.Id}", params: edit_params(other_sample, Lot: "NEWLOT01"), headers: bearer

      expect(response).to have_http_status(:forbidden)
      expect(other_sample.reload.Lot).not_to eq("NEWLOT01")
    end

    it "remains editable while on hold but not yet accepted" do
      sample = create_registered_sample
      sample.update_column(:SampleStatus, 3)

      put "/toxo/samples/#{sample.Id}", params: edit_params(sample, Lot: "NEWLOT01"), headers: bearer

      expect(response).to have_http_status(:ok)
      expect(sample.reload.Lot).to eq("NEWLOT01")
    end

    context "when the sample has already been accepted in lab" do
      it "still allows editing Lot/Level (accepted status alone does not lock them)" do
        sample = create_registered_sample
        sample.update_column(:AcceptanceDate, Time.current)

        put "/toxo/samples/#{sample.Id}", params: edit_params(sample, Lot: "NEWLOT01"), headers: bearer

        expect(response).to have_http_status(:ok)
        expect(sample.reload.Lot).to eq("NEWLOT01")
      end

      it "rejects a dispatch_date change" do
        sample = create_registered_sample
        sample.update_column(:AcceptanceDate, Time.current)

        put "/toxo/samples/#{sample.Id}", params: edit_params(sample, dispatch_date: 3.days.ago.to_date.to_s), headers: bearer

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to have_key("dispatch_date")
      end

      it "always allows appending a note, and saves it even when dispatch_date is rejected" do
        sample = create_registered_sample
        sample.update_column(:AcceptanceDate, Time.current)

        put "/toxo/samples/#{sample.Id}", params: edit_params(sample, dispatch_date: 3.days.ago.to_date.to_s, note: "lab note"), headers: bearer

        expect(response).to have_http_status(:unprocessable_content)
        expect(sample.reload.Comment).to include("lab note")
      end
    end

    context "when a measurement has an authorized result (Status: 5)" do
      it "rejects Lot/Level changes" do
        sample = create_registered_sample
        sample.measurements.first.update_column(:Status, 5)

        put "/toxo/samples/#{sample.Id}", params: edit_params(sample, Lot: "NEWLOT01"), headers: bearer

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to have_key("Lot")
        expect(sample.reload.Lot).not_to eq("NEWLOT01")
      end

      it "still allows appending a note" do
        sample = create_registered_sample
        sample.measurements.first.update_column(:Status, 5)

        put "/toxo/samples/#{sample.Id}", params: edit_params(sample, note: "post-authorization note"), headers: bearer

        expect(response).to have_http_status(:ok)
        expect(sample.reload.Comment).to include("post-authorization note")
      end
    end

    context "sample_collection_date" do
      it "can be set once when previously blank and within bounds" do
        sample = create_registered_sample
        sample.update_column(:sample_collection_date, nil)

        put "/toxo/samples/#{sample.Id}", params: edit_params(sample, sample_collection_date: Date.today.to_s), headers: bearer

        expect(response).to have_http_status(:ok)
        expect(sample.reload.sample_collection_date.to_date).to eq(Date.today)
      end

      it "rejects being changed once already set" do
        sample = create_registered_sample
        sample.update_column(:sample_collection_date, 2.days.ago)

        put "/toxo/samples/#{sample.Id}", params: edit_params(sample, sample_collection_date: Date.today.to_s), headers: bearer

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to have_key("sample_collection_date")
      end

      it "rejects a date after AcceptanceDate" do
        sample = create_registered_sample
        sample.update_column(:sample_collection_date, nil)
        sample.update_column(:AcceptanceDate, 2.days.ago)

        put "/toxo/samples/#{sample.Id}", params: edit_params(sample, sample_collection_date: Date.today.to_s), headers: bearer

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to have_key("sample_collection_date")
      end
    end

    it "partial save: saves the note even when Lot is rejected" do
      sample = create_registered_sample
      sample.measurements.first.update_column(:Status, 5)
      original_lot = sample.Lot

      put "/toxo/samples/#{sample.Id}", params: edit_params(sample, Lot: "NEWLOT01", note: "kept despite Lot rejection"), headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
      sample.reload
      expect(sample.Lot).to eq(original_lot)
      expect(sample.Comment).to include("kept despite Lot rejection")
    end
  end

  # ───── GET /toxo/samples — sorting ──────────────────────────────────────────

  describe "GET /toxo/samples (sorting)" do
    it "returns samples sorted by dispatch_date ascending" do
      early = create_registered_sample(code: "TX001A")
      early.update_column(:dispatch_date, 3.days.ago)
      late = create_registered_sample(code: "TX002A")
      late.update_column(:dispatch_date, 1.day.ago)

      get "/toxo/samples", params: { sort: "dispatch_date", direction: "asc" }, headers: bearer

      expect(response).to have_http_status(:ok)
      codes = json["data"].map { |s| s["Code"] }
      expect(codes.index("TX001A")).to be < codes.index("TX002A")
    end

    it "returns samples sorted by code descending" do
      create_registered_sample(code: "TX001A")
      create_registered_sample(code: "TX002A")

      get "/toxo/samples", params: { sort: "code", direction: "desc" }, headers: bearer

      expect(response).to have_http_status(:ok)
      codes = json["data"].map { |s| s["Code"] }
      expect(codes.index("TX002A")).to be < codes.index("TX001A")
    end

    it "returns samples sorted by level ascending" do
      create_registered_sample(code: "TX001A").update_column(:Level, "2")
      create_registered_sample(code: "TX002A").update_column(:Level, "1")

      get "/toxo/samples", params: { sort: "level", direction: "asc" }, headers: bearer

      expect(response).to have_http_status(:ok)
      codes = json["data"].map { |s| s["Code"] }
      expect(codes.index("TX002A")).to be < codes.index("TX001A")
    end

    it "returns samples sorted by level descending" do
      create_registered_sample(code: "TX001A").update_column(:Level, "2")
      create_registered_sample(code: "TX002A").update_column(:Level, "1")

      get "/toxo/samples", params: { sort: "level", direction: "desc" }, headers: bearer

      expect(response).to have_http_status(:ok)
      codes = json["data"].map { |s| s["Code"] }
      expect(codes.index("TX001A")).to be < codes.index("TX002A")
    end

    it "returns 200 with no sort params (no regression)" do
      create_registered_sample

      get "/toxo/samples", headers: bearer

      expect(response).to have_http_status(:ok)
    end

    it "silently ignores unknown sort column" do
      create_registered_sample

      get "/toxo/samples", params: { sort: "sql_injection", direction: "DROP" }, headers: bearer

      expect(response).to have_http_status(:ok)
    end
  end

  # ───── GET /toxo/samples — pagination envelope ──────────────────────────────

  describe "GET /toxo/samples (pagination)" do
    it "returns a data+meta envelope" do
      create_registered_sample

      get "/toxo/samples", headers: bearer

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to be_an(Array)
      expect(json["meta"]).to include("page", "per_page", "total_count", "total_pages")
      expect(json["meta"]["per_page"]).to eq(25)
    end

    it "paginates results at 25 per page" do
      30.times { |i| create_registered_sample(code: format("TX%03dA", i)) }

      get "/toxo/samples", params: { page: 1 }, headers: bearer
      expect(json["data"].size).to eq(25)
      expect(json["meta"]["total_count"]).to eq(30)
      expect(json["meta"]["total_pages"]).to eq(2)

      get "/toxo/samples", params: { page: 2 }, headers: bearer
      expect(json["data"].size).to eq(5)
    end

    it "returns an empty page when requesting a page beyond range" do
      create_registered_sample

      get "/toxo/samples", params: { page: 99 }, headers: bearer

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to eq([])
    end
  end

  # ───── GET /toxo/samples — search ───────────────────────────────────────────

  describe "GET /toxo/samples (search)" do
    it "filters by Code substring, case-insensitively" do
      match = create_registered_sample(code: "TX001A")
      other = create_registered_sample(code: "TX002A")

      get "/toxo/samples", params: { q: "tx001" }, headers: bearer

      ids = json["data"].map { |s| s["Id"] }
      expect(ids).to include(match.Id)
      expect(ids).not_to include(other.Id)
    end

    it "filters by Lot substring" do
      match = create_registered_sample(code: "TX001A")
      match.update_column(:Lot, "LOT-ALPHA")
      other = create_registered_sample(code: "TX002A")
      other.update_column(:Lot, "LOT-BETA")

      get "/toxo/samples", params: { q: "alpha" }, headers: bearer

      ids = json["data"].map { |s| s["Id"] }
      expect(ids).to include(match.Id)
      expect(ids).not_to include(other.Id)
    end

    it "ignores surrounding whitespace and returns the full list when blank" do
      create_registered_sample

      get "/toxo/samples", params: { q: "   " }, headers: bearer

      expect(json["data"].size).to eq(1)
    end

    it "combines search with sort" do
      a = create_registered_sample(code: "TX001A")
      b = create_registered_sample(code: "TX002A")

      get "/toxo/samples", params: { q: "TX00", sort: "code", direction: "desc" }, headers: bearer

      codes = json["data"].map { |s| s["Code"] }
      expect(codes).to eq([ "TX002A", "TX001A" ])
    end

    it "only searches within the policy scope" do
      match = create_registered_sample(code: "TX001A")

      other_contractor = create(:contractor, institution_id: institution.id)
      other_patient    = create(:toxo_patient, contractor: other_contractor)
      create_registered_sample(code: "TX001B", patient: other_patient)

      get "/toxo/samples", params: { q: "TX001" }, headers: bearer

      ids = json["data"].map { |s| s["Id"] }
      expect(ids).to eq([ match.Id ])
    end
  end

  # ───── DELETE /toxo/samples/:id ──────────────────────────────────────────────

  describe "DELETE /toxo/samples/:id" do
    it "destroys sample and measurements when deletable" do
      sample = create_registered_sample

      expect {
        delete "/toxo/samples/#{sample.Id}", headers: bearer
      }.to change(Toxo::Sample, :count).by(-1)
        .and change(Measurement, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 403 when sample is already accepted in lab" do
      sample = create_registered_sample
      sample.update_column(:AcceptanceDate, Time.current)

      delete "/toxo/samples/#{sample.Id}", headers: bearer

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 when sample belongs to another contractor" do
      other_contractor = create(:contractor, institution_id: institution.id)
      other_patient    = create(:toxo_patient, contractor: other_contractor)
      other_sample     = create_registered_sample(code: "TX002A", patient: other_patient)

      delete "/toxo/samples/#{other_sample.Id}", headers: bearer

      expect(response).to have_http_status(:forbidden)
    end
  end
end
