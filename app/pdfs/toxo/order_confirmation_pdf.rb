module Toxo
  # Podsumowanie zarejestrowanego zlecenia Toxo w formacie PDF — załącznik do
  # powiadomienia "Potwierdzenie zlecenia badania" (zdarzenie A).
  class OrderConfirmationPdf < Prawn::Document
    include Prawn::View

    def initialize(sample_id)
      super(page_size: "A4", page_layout: :portrait)
      @sample = Sample.find(sample_id)
      font_setup
      content
    end

    # Czcionka Unicode (TTF) jest wymagana do poprawnego renderowania polskich
    # znaków — domyślna czcionka AFM Prawn nie obsługuje UTF-8.
    def font_setup
      font_families.update("Nunito" => {
        normal: "vendor/assets/fonts/Nunito-Regular.ttf",
        bold:   "vendor/assets/fonts/Nunito-Bold.ttf"
      })
      font "Nunito"
    end

    def content
      fill_color "005072"
      text "Potwierdzenie zlecenia badania", size: 20, style: :bold
      fill_color "000000"
      move_down 6
      text "Data wygenerowania: #{Date.current.strftime('%F')}", size: 9
      move_down 20

      text "Dane zlecenia", size: 14, style: :bold
      move_down 8
      summary_table
      move_down 20

      text "Dziękujemy za złożenie zlecenia w Laboratorium Masdiag.", size: 10
    end

    private

    def summary_table
      table(summary_rows, cell_style: { borders: [:bottom], border_color: "DDDDDD", padding: [4, 6] },
                          column_widths: [180, 320]) do
        column(0).font_style = :bold
      end
    end

    def summary_rows
      [
        ["Kod próbki",            value(@sample.Code)],
        ["Numer próbki",         value(@sample.Code)],
        ["Typ materiału",        value(material_type)],
        ["Zlecone badania",      value(ordered_tests)],
        ["Tryb realizacji",      value(execution_mode)],
        ["Data pobrania",        value(@sample.sample_collection_date)],
        ["Data wysyłki",         value(@sample.try(:dispatch_date))],
        ["Data rejestracji",     value(@sample.RegistrationDate)],
        ["Uwagi",                value(@sample.try(:Comment))]
      ]
    end

    def material_type
      @sample.respond_to?(:MaterialType) ? @sample.MaterialType : nil
    end

    def ordered_tests
      return nil unless @sample.respond_to?(:measurements)

      @sample.measurements.map { |m| Toxo::Constants::PROJECT_NAMES[m.ProjectId] || m.ProjectId }.join(", ")
    end

    def execution_mode
      return nil unless @sample.respond_to?(:execution_mode)

      @sample.execution_mode == "expedited" ? "CITO" : "Standard"
    end

    def value(val)
      val.blank? ? "—" : val.to_s
    end
  end
end
