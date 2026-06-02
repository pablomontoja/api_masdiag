class ScannedDoc < ApplicationRecord
  belongs_to :sample, optional: true

  has_one_attached :page_pdf
  has_one_attached :markdown

  enum status: { ready: 0, ocr_pending: 1, transcribed: 2, failed: 9 }

  validates :source_filename, presence: true
  validates :page_checksum, presence: true, uniqueness: true

  scope :awaiting_ocr, -> { where(status: :ready) }

  def transcription
    markdown.download if markdown.attached?
  end
end
