class MonthlyForeignSamplesReportPdf < Prawn::Document

  def initialize()
    @projects_data = []
    Project.where(Id: [2, 3, 12, 21, 22, 23]).all.each do |project|
      @projects_data << {name: project.Name, data: ForeignSamplesMonthlyDataExtractor.call(project.Id).payload}
    end

    Project.where(Id: 10).all.each do |project|
      full_vitaeq10 = ForeignSamplesMonthlyDataExtractor.call(project.Id).payload

      vitaeq10 = full_vitaeq10.dup
      vitaeq10.authorized = vitaeq10.authorized.select{|c| c.fname.include?("vitaeq10")}
      vitaeq10.measured = vitaeq10.measured.select{|c| c.fname.include?("vitaeq10")}
      vitaeq10.canceled = vitaeq10.canceled.select{|c| c.fname.include?("vitaeq10")}

      @projects_data << {name: "WitAEQ10", data: vitaeq10}

      vita = full_vitaeq10.dup
      vita.authorized = vita.authorized.select{|c| c.fname.include?("vitamin-a")}
      vita.measured = vita.measured.select{|c| c.fname.include?("vitamin-a")}
      vita.canceled = vita.canceled.select{|c| c.fname.include?("vitamin-a")}

      @projects_data << {name: "WitA", data: vita}
    end

    super()
    
  	font_families.update("Arial" => {
	    :normal => Rails.root.join("lib/fonts/arial.ttf"),
	    :italic => Rails.root.join("lib/fonts/ariali.ttf"),
	    :bold => Rails.root.join("lib/fonts/arialbd.ttf"),
	    :bold_italic => Rails.root.join("lib/fonts/arialbi.ttf")
  	})
    
    font "Arial"

    header
    gap(30)
    main_table

    number_pages "strona <page>/<total>", {:at => [bounds.right - 50, 0], :align => :right, :size => 11}
  end

  def header
  	bold_style = { :font => "Arial", :font_style => :bold, :border_width => 0, :size => 12, :align => :center }
  	normal_style = { :font => "Arial", :border_width => 0, :size => 11, :align => :center, padding: 1 }
    
    font("Arial", size: 18, style: :bold) do
      text "Zestawienie wykonanych próbek w poprzednim miesiącu"
    end

    gap(10)
    table [["Data raportu: #{Date.today.to_s(:db)}"]], position: :left, :cell_style => normal_style
  end

  def main_table
  	# bold = { :font => "Arial", :font_style => :bold, :border_width => 0, :size => 11, :align => :left }
  	# normal = { :font => "Arial", :border_width => 0, :size => 10, :align => :left, padding: 1 }

    font("Arial", size: 16, style: :bold) do
      text "Cerascreen"
    end

    projects_cells = []
    projects_cells << ["Badanie", "Autoryzowane", "Zmierzone", "Wykonane", " ", "Odrzucone", "% Odrz."]
    
    @projects_data.each do |d|
      cera = d[:data]
      projects_cells << [d[:name].truncate(20), get_by_type(cera.authorized), get_by_type(cera.measured), (get_by_type(cera.authorized) + get_by_type(cera.measured)).to_s , " ",get_by_type(cera.canceled), canceled_ratio(cera)]
    end

  	table(projects_cells) do
      cells.align = :center
      cells.valign = :center
      cells.border_width = 0
      row(0).font_style = :bold
      column(3).size = 14
    end

    gap(30)

    font("Arial", size: 16, style: :bold) do
      text "Generic Assays"
    end

    projects_cells = []
    projects_cells << ["Badanie", "Autoryzowane", "Zmierzone", "Wykonane", " ", "Odrzucone", "% Odrz."]
    
    @projects_data.each do |d|
      ga = d[:data]
      projects_cells << [d[:name].truncate(20), get_by_type(ga.authorized, :ga), get_by_type(ga.measured, :ga), (get_by_type(ga.authorized, :ga) + get_by_type(ga.measured, :ga)) , " ",get_by_type(ga.canceled, :ga), canceled_ratio(ga, :ga)]
    end

    table(projects_cells) do
      cells.align = :center
      cells.valign = :center
      cells.border_width = 0
      row(0).font_style = :bold
      column(3).size = 14
    end

    start_new_page

    font("Arial", size: 16, style: :bold) do
      text "Lalen"
    end

    projects_cells = []
    projects_cells << ["Badanie", "Autoryzowane", "Zmierzone", "Wykonane", " ", "Odrzucone", "% Odrz."]
    
    @projects_data.each do |d|
      lalen = d[:data]
      projects_cells << [d[:name].truncate(20), get_by_type(lalen.authorized, :lalen), get_by_type(lalen.measured, :lalen), (get_by_type(lalen.authorized, :lalen) + get_by_type(lalen.measured, :lalen)) , " ",get_by_type(lalen.canceled, :lalen), canceled_ratio(lalen, :lalen)]
    end

    table(projects_cells) do
      cells.align = :center
      cells.valign = :center
      cells.border_width = 0
      row(0).font_style = :bold
      column(3).size = 14
    end

    gap(30)

    font("Arial", size: 16, style: :bold) do
      text "Lalen EU"
    end

    projects_cells = []
    projects_cells << ["Badanie", "Autoryzowane", "Zmierzone", "Wykonane", " ", "Odrzucone", "% Odrz."]
    
    @projects_data.each do |d|
      lalen = d[:data]
      projects_cells << [d[:name].truncate(20), get_by_type(lalen.authorized, :lalen_eu), get_by_type(lalen.measured, :lalen_eu), (get_by_type(lalen.authorized, :lalen_eu) + get_by_type(lalen.measured, :lalen_eu)) , " ",get_by_type(lalen.canceled, :lalen_eu), canceled_ratio(lalen, :lalen_eu)]
    end

    table(projects_cells) do
      cells.align = :center
      cells.valign = :center
      cells.border_width = 0
      row(0).font_style = :bold
      column(3).size = 14
    end

    start_new_page

    font("Arial", size: 16, style: :bold) do
      text "Trime"
    end

    projects_cells = []
    projects_cells << ["Badanie", "Autoryzowane", "Zmierzone", "Wykonane", " ", "Odrzucone", "% Odrz."]
    
    @projects_data.each do |d|
      trime = d[:data]
      projects_cells << [d[:name].truncate(20), get_by_type(trime.authorized, :trime), get_by_type(trime.measured, :trime), (get_by_type(trime.authorized, :trime) + get_by_type(trime.measured, :trime)) , " ",get_by_type(trime.canceled, :trime), canceled_ratio(trime, :trime)]
    end

    table(projects_cells) do
      cells.align = :center
      cells.valign = :center
      cells.border_width = 0
      row(0).font_style = :bold
      column(3).size = 14
    end

    gap(30)

    font("Arial", size: 16, style: :bold) do
      text "Physikit"
    end

    projects_cells = []
    projects_cells << ["Badanie", "Autoryzowane", "Zmierzone", "Wykonane", " ", "Odrzucone", "% Odrz."]
    
    @projects_data.each do |d|
      physikit = d[:data]
      projects_cells << [d[:name].truncate(20), get_by_type(physikit.authorized, :physikit), get_by_type(physikit.measured, :physikit), (get_by_type(physikit.authorized, :physikit) + get_by_type(physikit.measured, :physikit)) , " ",get_by_type(physikit.canceled, :physikit), canceled_ratio(physikit, :physikit)]
    end

    table(projects_cells) do
      cells.align = :center
      cells.valign = :center
      cells.border_width = 0
      row(0).font_style = :bold
      column(3).size = 14
    end

    start_new_page

    font("Arial", size: 16, style: :bold) do
      text "AMC Israel"
    end

    projects_cells = []
    projects_cells << ["Badanie", "Autoryzowane", "Zmierzone", "Wykonane", " ", "Odrzucone", "% Odrz."]
    
    @projects_data.each do |d|
      amc = d[:data]
      projects_cells << [d[:name].truncate(20), get_by_type(amc.authorized, :amc), get_by_type(amc.measured, :amc), (get_by_type(amc.authorized, :amc) + get_by_type(amc.measured, :amc)) , " ",get_by_type(amc.canceled, :amc), canceled_ratio(amc, :amc)]
    end

    table(projects_cells) do
      cells.align = :center
      cells.valign = :center
      cells.border_width = 0
      row(0).font_style = :bold
      column(3).size = 14
    end

    gap(30)

    font("Arial", size: 16, style: :bold) do
      text "Luxbiotech"
    end

    projects_cells = []
    projects_cells << ["Badanie", "Autoryzowane", "Zmierzone", "Wykonane", " ", "Odrzucone", "% Odrz."]
    
    @projects_data.each do |d|
      luxbiotech = d[:data]
      projects_cells << [d[:name].truncate(20), get_by_type(luxbiotech.authorized, :luxbiotech), get_by_type(luxbiotech.measured, :luxbiotech), (get_by_type(luxbiotech.authorized, :luxbiotech) + get_by_type(luxbiotech.measured, :luxbiotech)) , " ",get_by_type(luxbiotech.canceled, :luxbiotech), canceled_ratio(luxbiotech, :luxbiotech)]
    end

    table(projects_cells) do
      cells.align = :center
      cells.valign = :center
      cells.border_width = 0
      row(0).font_style = :bold
      column(3).size = 14
    end

    
  end

  def get_by_type(arr, type = :cerascreen)
    arr.select{|pl| pl[:type] == type}.size
  end

  def canceled_ratio(arr, type = :cerascreen)
    sum = get_by_type(arr.authorized, type) + get_by_type(arr.measured, type) + get_by_type(arr.canceled, type)
    canc = get_by_type(arr.canceled, type)
    return "-" if canc == 0
    ratio = ((canc*100.00)/sum).round(1)
    "#{ratio}%"
  end

  def gap(size)
  	move_down size
  end

end

# get_gender_string(@patient.Gender, I18n.locale)

