require 'rails_helper'

RSpec.describe Shopify::ProductMapper do
  before do
    create(:project)  # Id 2
    create(:project2) # Id 3
  end

  let(:mapping) do
    {
      "41234567890123" => [2],
      "41234567890124" => [3, 2]
    }
  end

  before do
    allow(described_class).to receive(:mapping).and_return(mapping)
  end

  it 'resolves a variant mapped to a single Project' do
    expect(described_class.project_ids_for("41234567890123")).to eq([2])
  end

  it 'resolves a variant mapped to multiple Projects (bundle)' do
    expect(described_class.project_ids_for("41234567890124")).to eq([3, 2])
  end

  it 'returns an empty array for an unmapped variant, without raising' do
    expect(described_class.project_ids_for("00000000000000")).to eq([])
  end

  it 'flags a configured Project id that does not exist' do
    allow(described_class).to receive(:mapping).and_return({ "999" => [999_999] })

    expect { described_class.validate_targets! }.to raise_error(/999999/)
  end

  it 'does not flag mappings whose Project ids all exist' do
    expect { described_class.validate_targets! }.not_to raise_error
  end
end
