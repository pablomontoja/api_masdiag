FactoryBot.define do
  factory :scanned_doc do
    source_filename { "scan_#{SecureRandom.hex(4)}.pdf" }
    page_checksum   { SecureRandom.hex(32) }
    source          { "scan_watcher" }
    status          { :ready }

    trait :with_page_pdf do
      after(:create) do |doc|
        doc.page_pdf.attach(
          io: StringIO.new("%PDF-1.4 minimal"),
          filename: "page.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :ocr_pending do
      status { :ocr_pending }
    end

    trait :transcribed do
      status { :transcribed }
      transcribed_at { Time.current }
      after(:create) do |doc|
        doc.markdown.attach(
          io: StringIO.new("# OCR result\n"),
          filename: "#{doc.page_checksum}.md",
          content_type: "text/markdown"
        )
      end
    end

    trait :failed do
      status          { :failed }
      processing_error { "Connection refused" }
    end
  end
end
