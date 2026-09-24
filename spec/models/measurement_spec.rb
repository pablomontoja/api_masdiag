require "rails_helper"

RSpec.describe Measurement, type: :model do
  describe "#report_pdf_url" do
    context "when the measurement has no online_file" do
      it "returns nil" do
        measurement = create(:measurement, project: create(:project_without_fixed_id))

        expect(measurement.report_pdf_url).to be_nil
      end
    end

    context "when the online_file has no file_contents" do
      it "returns nil" do
        measurement = create(:measurement, project: create(:project_without_fixed_id))
        create(:online_file, measurement: measurement, file_contents: nil)

        expect(measurement.reload.report_pdf_url).to be_nil
      end
    end

    context "when the online_file has file_contents" do
      it "returns the same signed URL the toxo API exposes as report_pdf_url" do
        measurement = create(:measurement, project: create(:project_without_fixed_id))
        create(:online_file, measurement: measurement, file_contents: "%PDF-1.4 fake pdf bytes", filename: "wynik.pdf")

        url = measurement.reload.report_pdf_url

        expect(url).to be_present
        expect(url).to match(%r{\Ahttp://})
      end
    end
  end
end
