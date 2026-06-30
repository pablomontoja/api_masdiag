require 'rails_helper'

RSpec.describe LalenApi::KitTests, type: :model do
  subject(:kit_tests) { described_class.new(barcode: "AU1234567", tests: ["vitamin-d", "hba1c"]) }

  describe 'validations' do
    it 'is valid with barcode and non-empty tests array' do
      expect(kit_tests).to be_valid
    end

    it 'is invalid when barcode is blank' do
      kit_tests.barcode = ""
      expect(kit_tests).not_to be_valid
      expect(kit_tests.errors[:barcode]).to be_present
    end

    it 'is invalid when barcode is nil' do
      kit_tests.barcode = nil
      expect(kit_tests).not_to be_valid
    end

    it 'is invalid when tests is empty array' do
      kit_tests.tests = []
      expect(kit_tests).not_to be_valid
      expect(kit_tests.errors[:tests]).to be_present
    end

    it 'is invalid when tests is nil' do
      kit_tests.tests = nil
      expect(kit_tests).not_to be_valid
    end
  end

  describe '#as_json' do
    it 'serialises to { barcode:, tests: } with string keys' do
      result = kit_tests.as_json
      expect(result).to eq("barcode" => "AU1234567", "tests" => ["vitamin-d", "hba1c"])
    end
  end
end
