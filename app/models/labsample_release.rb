class LabsampleRelease < ApplicationRecord
  has_one_attached :archive

  def self.latest
    order(:created_at).last
  end
end
