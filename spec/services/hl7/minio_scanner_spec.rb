require 'rails_helper'

RSpec.describe Hl7::MinioScanner do
  let(:hl7_content) { File.read(Rails.root.join("spec/metals.hl7")) }
  let(:bucket_name) { "hl7-results" }
  let(:s3_key)      { "results/test_#{SecureRandom.hex(4)}.hl7" }

  let(:s3_object) do
    double("S3Object", key: s3_key, etag: "abc123", size: hl7_content.bytesize)
  end

  let(:s3_body)   { double("body", read: hl7_content) }
  let(:s3_client) { instance_double(Aws::S3::Client) }

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
    allow(Rails.application.credentials).to receive(:dig).with(:hl7_s3, :access_key_id).and_return("key")
    allow(Rails.application.credentials).to receive(:dig).with(:hl7_s3, :secret_access_key).and_return("secret")
    allow(Rails.application.credentials).to receive(:dig).with(:hl7_s3, :endpoint).and_return("http://minio:9000")
    allow(Rails.application.credentials).to receive(:dig).with(:hl7_s3, :bucket).and_return(bucket_name)

    list_response = double("list_response", contents: [s3_object])
    allow(s3_client).to receive(:list_objects_v2).with(bucket: bucket_name).and_return(list_response)
    allow(s3_client).to receive(:get_object).with(bucket: bucket_name, key: s3_key)
                                             .and_return(double("get_response", body: s3_body))

    allow_any_instance_of(Hl7Import).to receive_message_chain(:hl7_file, :attach)
  end

  describe "#scan_and_import" do
    context "when matching measurement exists" do
      let(:sample) do
        create(:sample, Code: "A6Y1IF")
      end
      let(:project) do
        Project.find_or_create_by(Id: 32) do |p|
          p.Name = "NutriPATH Metals"
          p.WithCutter = false
          p.PlateDimensionX = 8
          p.PlateDimensionY = 12
          p.InjectionVolume = 0
          p.is_blocked_online = false
          p.eng_name = "NutriPATH Metals"
        end
      end
      let(:measurement) { create(:measurement, sample: sample, ProjectId: 32, Status: 1) }

      before do
        project
        measurement
        allow(Hl7::MeasurementImportJob).to receive(:perform_later)
      end

      it "creates an Hl7Import record with extracted metadata" do
        expect {
          described_class.new.scan_and_import
        }.to change(Hl7Import, :count).by(1)

        import = Hl7Import.last
        expect(import.s3_key).to eq(s3_key)
        expect(import.kit_code_extracted).to eq("A6Y1IF")
        expect(import.hl7_test_code).to eq("UCR,usEssEl,UsMetox")
      end

      it "links the import to the measurement and enqueues processing job" do
        described_class.new.scan_and_import

        import = Hl7Import.last
        expect(import.measurement_id).to eq(measurement.Id)
        expect(Hl7::MeasurementImportJob).to have_received(:perform_later).with(import.id)
      end

      it "returns new_files count and empty errors" do
        result = described_class.new.scan_and_import
        expect(result[:new_files]).to eq(1)
        expect(result[:errors]).to be_empty
      end
    end

    context "when no matching sample exists" do
      before { create(:sample, Code: "A6Y1IF") }

      it "marks the import as awaiting_registration" do
        described_class.new.scan_and_import
        import = Hl7Import.last
        expect(import).not_to be_nil
        expect(import.status).to eq("awaiting_registration")
      end

      it "does not enqueue a processing job" do
        expect(Hl7::MeasurementImportJob).not_to receive(:perform_later)
        described_class.new.scan_and_import
      end
    end

    context "when file was already imported" do
      before { create(:hl7_import, s3_key: s3_key) }

      it "skips the file and creates no new record" do
        expect {
          described_class.new.scan_and_import
        }.not_to change(Hl7Import, :count)
      end
    end

    context "when MinIO raises a ServiceError" do
      before do
        allow(s3_client).to receive(:list_objects_v2)
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "Connection refused"))
      end

      it "returns an error hash without raising" do
        result = described_class.new.scan_and_import
        expect(result[:new_files]).to eq(0)
        expect(result[:errors]).to include(match(/MinIO Error/))
      end
    end
  end
end
