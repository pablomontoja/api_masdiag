require 'csv'

io = File.open('tmp/goldcup-toxo.csv', 'r')
csv = CSV.new(io, headers: true, header_converters: :symbol, col_sep: ";")
analytes = csv.to_a.map {|row| row.to_hash }

puts %Q(
project = Project.create!\(                                                       
        Name: "Goldcup TOX",                                     
        Description: "Goldcup TOX",                   
        WithCutter: true,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Goldcup TOX",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "toxo@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Goldcup TOX",
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
  ExcludedFromStatistic: true
\)

men_analyte_range = AnalyteRange.create!(
  Name: "Mężczyzna",
  AgeFrom: 0,
  AgeTo: 150,
  Gender: 0,
  Min: 0.0,
  Max: #{a[:cutoff_min]},
  AnalyteId: analyte.Id,
  AgeFromMonth: 0,
  AgeToMonth: 0,
  AgeFromInMonths: 0,
  AgeToInMonths: 1800,
  Multiplier: 0.1e1,
  AcceptableMin: 0.0,
  AcceptableMax: #{a[:cutoff_min]},
  MaterialType: 9
)

women_analyte_range = AnalyteRange.create!(
  Name: "Kobieta",
  AgeFrom: 0,
  AgeTo: 150,
  Gender: 1,
  Min: 0.0,
  Max: #{a[:cutoff_min]},
  AnalyteId: analyte.Id,
  AgeFromMonth: 0,
  AgeToMonth: 0,
  AgeFromInMonths: 0,
  AgeToInMonths: 1800,
  Multiplier: 0.1e1,
  AcceptableMin: 0.0,
  AcceptableMax: #{a[:cutoff_min]},
  MaterialType: 9
)
)
end