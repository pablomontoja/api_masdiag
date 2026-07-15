module LalenApi
  class KitTests
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Serializers::JSON
    include ActiveModel::Validations

    attribute :barcode, :string
    attribute :tests, default: -> { [] }

    validates :barcode, presence: true
    validate :tests_not_empty

    def as_json(_opts = {})
      { "barcode" => barcode, "tests" => tests }
    end

    private

    def tests_not_empty
      errors.add(:tests, "can't be blank") if tests.blank?
    end
  end
end
