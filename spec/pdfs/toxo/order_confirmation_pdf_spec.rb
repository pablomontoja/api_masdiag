require "rails_helper"

RSpec.describe Toxo::OrderConfirmationPdf do
  let(:sample) { create(:sample, Code: "TXPDF1") }

  it "renders a non-empty PDF from the sample" do
    pdf = described_class.new(sample.Id).render
    expect(pdf).to start_with("%PDF")
    expect(pdf.bytesize).to be > 500
  end

  it "builds the summary rows from the sample fields without error" do
    expect { described_class.new(sample.Id) }.not_to raise_error
  end
end
