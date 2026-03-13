class ToxicologyQuantProject < ActiveRecord::Migration[7.0]
  def change

    ActiveRecord::Base.transaction do
      project = Project.create!(                                                       
        Name: "Analiza toksykologiczna ilościowa (LC-MS/MS)",                                     
        Description: "Analiza toksykologiczna ilościowa (LC-MS/MS)",                   
        WithCutter: false,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Analiza toksykologiczna ilościowa (LC-MS/MS)",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "toxo@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Quantitative toxicological analysis",
        is_active: true
      )

      toxo = Project.find(31)

      toxo.analytes.where(material_type: :whole_blood).each do |analyte|
        %i[whole_blood urine aqueous_humor blood_plasma blood_serum drainage].each do |mat|
          analyte_dup = analyte.dup
          analyte_dup.assign_attributes(ProjectId: project.Id, material_type: mat.to_sym)
          analyte_dup.save

          analyte.analyte_ranges.each do |ar|
            ar_dup = ar.dup
            ar_dup.assign_attributes(AnalyteId: analyte_dup.Id)
            ar_dup.save
          end
        end
      end

      Project.create!(                                                       
        Name: "Analiza toksykologiczna jakościowa (LC-MS/MS)",                                     
        Description: "Analiza toksykologiczna jakościowa (LC-MS/MS)",                   
        WithCutter: false,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Analiza toksykologiczna jakościowa (LC-MS/MS)",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "toxo@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Qualitative toxicological analysis",
        is_active: true
      )

      Project.create!(                                                       
        Name: "Analiza ilościowa kwasu γ-hydroksymasłowego (GHB) (LC-MS/MS)",                                     
        Description: "Analiza ilościowa kwasu γ-hydroksymasłowego (GHB) (LC-MS/MS)",                   
        WithCutter: false,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Analiza ilościowa kwasu γ-hydroksymasłowego (GHB) (LC-MS/MS)",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "toxo@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Quantitative analysis of γ-hydroxybutyric acid (GHB)",
        is_active: true
      )
    end
 

  end
end
