class RegistrationConfirmationThreeOmdPdf < Prawn::Document
   # // `include` instead of subclassing Prawn::Document
  # // as advised by the official manual
  include Prawn::View


  def initialize(id)
    super(page_size: "A4", page_layout: :portrait, left_margin: 0, right_margin: 0, top_margin: 20, bottom_margin: 0)
    @sample = Sample.find(id)
    font_setup
    content
  end

  def font_setup  
    font_families.update("Nunito" => {
      :normal => "vendor/assets/fonts/Nunito-Regular.ttf",
      :bold => "vendor/assets/fonts/Nunito-Bold.ttf",
      :arrows => "vendor/assets/fonts/Nunito-Regular-with-arrows.ttf",
    })
    font "Nunito"

    @font_color = "353940"
    @masdiag_blue = "005072" 
  end
   
  def content
    repeat(:all) do
      header_section
    end

    move_down 30

    orderer_header_section

    move_down 5

    ["Tytuł naukowy", "Imię", "Nazwisko", "Numer telefonu", "Nazwa Jednostki", "Adres jednostki"].each do |attribute|
      orderer_data(attribute)
    end

    email_section

    move_down 30

    sample_section_header
    
    move_down 5

    sample_section

    move_down 30

    patient_section_header

    move_down 5

    patient_section

    footer_section

    # ["Tytuł naukowy", "Imię", "Nazwisko", "Numer telefonu", "Nazwa Jednostki", "Adres jednostki (ulica, kod pocztowy, miasto)", "Terapia z wykorzystaniem preparatów zawierających L-DOPA?", "Potwierdź dodatkowo, że pacjent nie przyjmuje żadnych preparatów zawierających L-DOPA z poniższych:", "Hipotonia", "Opóźniony rozwój psychoruchowy", "Objawy ze strony układu autonomicznego", "Zaburzenia ruchowe", "Zaburzenia zachowania", "Zmiany w obrazowaniu OUN (TK, RM)", "Zmienność dobowa objawów"]
     
  end  

  #SECTIONS

  def header_section  
    t1_r1_c1 = make_cell(content: "POTWIERDZENIE REJESTRACJI PRÓBKI", width: 381, align: :left, valign: :top, font_style: :bold, size: 16, background_color: @masdiag_blue, text_color: "FFFFFF", padding: [4,0,0,48], leading: -3)
    t1_r1_c2 = { image: "#{Rails.root}/app/assets/images/logo_masdiag.png", scale: 0.5, width: 214, padding: [0,0,0,20], vposition: :center} 
   
    table(
      [
        [t1_r1_c1, t1_r1_c2]       
      ],
      :cell_style => { :borders => [], height: 40 } 
    )
  end

  def orderer_header_section
    t9_r1_c1 = make_cell(content: "LEKARZ ZLECAJĄCY", width: 230, align: :left, valign: :top, size: 12, background_color: @masdiag_blue, text_color: "FFFFFF")  
    table(
     [
       [t9_r1_c1]
     ],
     :cell_style => { :borders => [], :padding => [2,0,5,48], font_style: :bold}
    )

  end


  def orderer_data(attribute)
    answer = Answer.joins(:survey_question).where("survey_questions.question_text LIKE ?","%#{attribute}%").find_by(Sample_id: @sample.Id)
    return if answer.nil?
    t1_r1_c1 = make_cell(content: attribute, width: 100, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)
    t1_r1_c2 = make_cell(content: "#{answer.other_field_text}", width: 400, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :normal, inline_format: true)
    
    table(
      [
        [t1_r1_c1,t1_r1_c2]
      ],
      :cell_style => { borders: [], border_width: 0.1, padding: [0,0,0,0] }, position: :center 
    )
  end

  def email_section
    pat = @sample.patient 

    t1_r1_c1 = make_cell(content: "Adres email:", width: 100, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)
    t1_r1_c2 = make_cell(content: "#{pat.email}", width: 400, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :normal, inline_format: true)    
    
    table(
      [
        [t1_r1_c1,t1_r1_c2]
      ],
      :cell_style => { borders: [], border_width: 0.1, padding: [0,0,0,0] }, position: :center 
    )
  end

  def sample_section_header
    t9_r1_c1 = make_cell(content: "DANE PRÓBKI", width: 230, align: :left, valign: :top, size: 12, background_color: @masdiag_blue, text_color: "FFFFFF")
  
    table(
      [
        [t9_r1_c1]
      ],
      :cell_style => { :borders => [], :padding => [2,0,5,48], font_style: :bold}
    )
  end

  def sample_section    
    t1_r1_c1 = make_cell(content: "Kod próbki", width: 130, align: :left, valign: :center, size: 12, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)
    t1_r1_c2 = make_cell(content: "#{@sample.Code}", width: 370, align: :left, valign: :top, size: 18, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)

    t1_r2_c1 = make_cell(content: "Data pobrania próbki", width: 130, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)
    t1_r2_c2 = make_cell(content: @sample.sample_collection_date.strftime("%F"), width: 370, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :normal, inline_format: true)

    t1_r3_c1 = make_cell(content: "Data rejestracji próbki", width: 130, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)
    t1_r3_c2 = make_cell(content: @sample.RegistrationDate.strftime("%F"), width: 370, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :normal, inline_format: true)
    
    table(
      [
        [t1_r1_c1,t1_r1_c2],
        [t1_r2_c1,t1_r2_c2],
        [t1_r3_c1,t1_r3_c2]
      ],
      :cell_style => { borders: [], border_width: 0.1, padding: [0,0,0,0] }, position: :center 
    )
  end

  def patient_section_header
    t9_r1_c1 = make_cell(content: "DANE PACJENTA", width: 230, align: :left, valign: :top, size: 12, background_color: @masdiag_blue, text_color: "FFFFFF")
  
    table(
     [
       [t9_r1_c1]
     ],
     :cell_style => { :borders => [], :padding => [2,0,5,48], font_style: :bold}
    )
  end

  def patient_section
    pat = @sample.patient 

    t1_r1_c1 = make_cell(content: "Imię", width: 100, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)
    t1_r1_c2 = make_cell(content: "#{pat.FirstName}", width: 400, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :normal, inline_format: true)

    t1_r2_c1 = make_cell(content: "Nazwisko", width: 100, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)
    t1_r2_c2 = make_cell(content: "#{pat.LastName}", width: 400, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :normal, inline_format: true)

    t1_r3_c1 = make_cell(content: "PESEL", width: 100, align: :left, valign: :center, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)
    t1_r3_c2 = make_cell(content: "#{pat.Pesel}", width: 400, align: :left, valign: :top, size: 18, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)

    t1_r4_c1 = make_cell(content: "Płeć", width: 100, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)
    t1_r4_c2 = make_cell(content: "#{get_gender(pat)}", width: 400, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :normal, inline_format: true)

    t1_r5_c1 = make_cell(content: "Data urodzenia", width: 100, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :bold, inline_format: true)
    t1_r5_c2 = make_cell(content: "#{pat.BirthDate.strftime("%F")}", width: 400, align: :left, valign: :top, size: 10, borders: [:top, :left], padding: [5,0,0,10], font_style: :normal, inline_format: true)
    
    
    table(
      [
        [t1_r3_c1,t1_r3_c2],
        [t1_r1_c1,t1_r1_c2],
        [t1_r2_c1,t1_r2_c2],
        [t1_r4_c1,t1_r4_c2],
        [t1_r5_c1,t1_r5_c2],
      ],
      :cell_style => { borders: [], border_width: 0.1, padding: [0,0,0,0] }, position: :center 
    )
  end
    

  def footer_section   
    repeat(:all) do    
      t14_r1_c1 = make_cell(
        content: 
        "<b>Dane laboratorium wykonującego badanie
        Masdiag sp. z o.o.</b>
        Laboratorium Diagnostyczne Masdiag
        ul. Żeromskiego 33, 01–882 Warszawa
        www.masdiag.pl, email: pomoc@masdiag.pl
        tel.: +48 602 228 824",
        width: 214, size: 8, align: :left, leading: -2, inline_format: true)

      move_cursor_to 80

      t14 = table(
        [
          [t14_r1_c1]
        ],
        :cell_style => { borders: [], border_width: 0, padding: [0,0,0,48], leading: -2 },
        position: :left
      )
    end

    string = 'str. <page>/<total>'
   
    options = {
      at: [bounds.right - 55, 25],
      width: 20,
      align: :right,
      start_count_at: 1,
      size: 6
    }
   
    number_pages string, options
  end

  def get_gender(patient)
    res = "-"
    res = "M" if patient.Gender == 0
    res = "K" if patient.Gender == 1
    res
  end
      
end