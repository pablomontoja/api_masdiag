module LalenApi
	class RegisterKit
		include ActiveModel::Model
		include ActiveModel::Attributes
		include ActiveModel::Serializers::JSON
		include ActiveModel::Validations

		EMAIL_REGEXP = /\A[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+\z/

		attribute :barcode, :string
		attribute :email, :string
		attribute :first_name, :string
		attribute :last_name, :string
		attribute :birth_date, :datetime
		attribute :sample_collection_date, :datetime
		attribute :gender, :integer

		validates :barcode, presence: true
		validates :email, if: ->(reg_kit) { !reg_kit.email.blank? }, format: { with: EMAIL_REGEXP, message: "invalid email address" }
		validates :first_name, presence: true
		validates :last_name, presence: true
		validates :birth_date, presence: true
		# TO DO at some point in time FAKE PATIENT conditions should be removed
		validates :sample_collection_date, presence: true, unless: Proc.new { |rk| rk.first_name == "FAKE" && rk.last_name == "PATIENT" }
		validates :gender, presence: true

	private

	end
end


# {
#   "barcode": "USDEMO302",
#   "sample_collection_date": "2024-06-22",
#   "email": "john.doe@email.com",
#   "first_name": "John",
#   "last_name": "Doe",
#   "birth_date": "1970-01-01",
#   "gender": 0,
# }