require 'csv'

io = File.open('tmp/amino-urine-0-36.csv', 'r')
csv = CSV.new(io, headers: true, header_converters: :symbol, col_sep: ";")
analytes = csv.to_a.map {|row| row.to_hash }

puts %Q(
project = Project.create!\(                                                       
        Name: "Profil aminokwasów w moczu",                                     
        Description: "Profil aminokwasów w moczu",                   
        WithCutter: true,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Profil aminokwasów w moczu",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "anna.krol@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Amino acid profile in urine",
        is_active: true
      \)
)

analytes.each do |a|
  
puts %Q(
analyte = Analyte.create!\(
  Name: "#{a[:mq_name]}",                                                  
  ProjectId: project.Id,                                                 
  IsCalculatedFromOthers: false,                                 
  CutoffMin: #{a[:cutoff_min]},                                                
  CutoffMax: #{a[:cutoff_max]},                                              
  Unit: "#{a[:unit]}",                                                
  NameInReport: "#{a[:name]}",                                          
  NameInAPI: "#{a[:eng_name].downcase}",                                             
  analysis_method_name_in_batch: nil,                            
  AnalysisMethodPolarity: nil,                                   
  is_required: true,                                             
  NameInStandLab: nil,
  ExcludedFromStatistic: true,
  material_type: 5
\)
)

next if a[:age_from].blank?

puts %Q(
men_analyte_range = AnalyteRange.create!(
  Name: "Mężczyzna",
  AgeFrom: 0,
  AgeTo: 3,
  Gender: 0,
  Min: #{a[:range_min]},
  Max: #{a[:range_max]},
  AnalyteId: analyte.Id,
  AgeFromInMonths: #{a[:age_from]},
  AgeToInMonths: #{a[:age_to]},
  Multiplier: 0.1e1,
  AcceptableMin: #{a[:range_min]},
  AcceptableMax: #{a[:cutoff_min]}
)

women_analyte_range = AnalyteRange.create!(
  Name: "Kobieta",
  AgeFrom: 0,
  AgeTo: 3,
  Gender: 1,
  Min: #{a[:range_min]},
  Max: #{a[:range_max]},
  AnalyteId: analyte.Id,
  AgeFromInMonths: #{a[:age_from]},
  AgeToInMonths: #{a[:age_to]},
  Multiplier: 0.1e1,
  AcceptableMin: #{a[:range_min]},
  AcceptableMax: #{a[:range_max]}
)
)

end

io = File.open('tmp/amino-urine-36-1800.csv', 'r')
csv = CSV.new(io, headers: true, header_converters: :symbol, col_sep: ";")
analytes = csv.to_a.map {|row| row.to_hash }

analytes.each do |a|
puts %Q(
analyte = Analyte.where\(ProjectId: project.Id\).find_by!\(Name: "#{a[:mq_name]}"\)

men_analyte_range = AnalyteRange.create!(
  Name: "Mężczyzna",
  AgeFrom: 3,
  AgeTo: 150,
  Gender: 0,
  Min: #{a[:range_min]},
  Max: #{a[:range_max]},
  AnalyteId: analyte.Id,
  AgeFromInMonths: #{a[:age_from]},
  AgeToInMonths: #{a[:age_to]},
  Multiplier: 0.1e1,
  AcceptableMin: #{a[:range_min]},
  AcceptableMax: #{a[:cutoff_min]}
)

women_analyte_range = AnalyteRange.create!(
  Name: "Kobieta",
  AgeFrom: 3,
  AgeTo: 150,
  Gender: 1,
  Min: #{a[:range_min]},
  Max: #{a[:range_max]},
  AnalyteId: analyte.Id,
  AgeFromInMonths: #{a[:age_from]},
  AgeToInMonths: #{a[:age_to]},
  Multiplier: 0.1e1,
  AcceptableMin: #{a[:range_min]},
  AcceptableMax: #{a[:range_max]}
)
)


end