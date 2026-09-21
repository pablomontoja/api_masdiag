# == Schema Information
#
# Table name: scanned_docs
#
#  id               :bigint           not null, primary key
#  source_filename  :string(255)      not null
#  page_checksum    :string(64)       not null
#  document_key     :string(255)
#  status           :integer          default(0), not null
#  source           :string(255)      default("scan_watcher"), not null
#  sample_id        :integer
#  captured_at      :datetime
#  received_at      :datetime
#  ocr_started_at   :datetime
#  transcribed_at   :datetime
#  processing_error :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class ScannedDoc < ApplicationRecord
  belongs_to :sample, optional: true

  has_one_attached :page_pdf
  has_one_attached :markdown

  enum :status, { ready: 0, ocr_pending: 1, transcribed: 2, failed: 9 }

  validates :source_filename, presence: true
  validates :page_checksum, presence: true, uniqueness: true

  scope :awaiting_ocr, -> { where(status: :ready) }

  def transcription
    markdown.download if markdown.attached?
  end
end
