class ToxicologyQuantProject < ActiveRecord::Migration[7.0]
  def change
    reset_auto_increment("Projects", column: "Id")
    reset_auto_increment("Analytes", column: "Id")
    reset_auto_increment("AnalyteRanges", column: "Id")

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
        analyte_name = analyte.Name.split(" 1").first
        [" 1", " 2"].each do |n|
          %i[whole_blood urine aqueous_humor blood_plasma blood_serum drainage].each do |mat|
            analyte_dup = analyte.dup
            analyte_dup.assign_attributes(Name: "#{analyte_name}#{n}", ProjectId: project.Id, material_type: mat.to_sym, NameInAPI: "#{analyte.NameInAPI}_#{n.strip}", NameInReport: "#{analyte.NameInReport}#{n}")
            analyte_dup.save

            analyte.analyte_ranges.each do |ar|
              ar_dup = ar.dup
              ar_dup.assign_attributes(AnalyteId: analyte_dup.Id)
              ar_dup.save
            end
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
        Name: 'Analiza toksykologiczna typu "GHB" (LC-MS/MS)',                                     
        Description: 'Analiza toksykologiczna typu "GHB" (LC-MS/MS)',                   
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
        eng_name: '"GHB" toxicological analysis',
        is_active: true
      )

      Project.create!(                                                       
        Name: "Analiza toksykologiczna na zlecenie",                                     
        Description: "Analiza toksykologiczna na zlecenie",                   
        WithCutter: false,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Analiza toksykologiczna na zlecenie",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "toxo@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Custom Toxicological Analysis",
        is_active: true
      )
    end

    ActiveRecord::Base.transaction do
      %i[whole_blood urine aqueous_humor blood_plasma blood_serum drainage].each do |mat|      
        # GHB 1
        Analyte.create!(
          Name: "GHB 1",
          ProjectId: 41,
          IsCalculatedFromOthers: true,
          CutoffMin: 0.1,
          CutoffMax: 20,
          Unit: "µg/mL",
          NameInReport: "Kwas γ-hydroksymasłowy (GHB) MRM1",
          NameInAPI: "ghb_1",
          analysis_method_name_in_batch: nil,
          AnalysisMethodPolarity: nil,
          is_required: true,
          NameInStandLab: nil,
          ExcludedFromStatistic: true,
          material_type: mat.to_sym
        )

        # GHB 2
        Analyte.create!(
          Name: "GHB 2",
          ProjectId: 41,
          IsCalculatedFromOthers: true,
          CutoffMin: 0.1,
          CutoffMax: 20,
          Unit: "µg/mL",
          NameInReport: "Kwas γ-hydroksymasłowy (GHB) MRM2",
          NameInAPI: "ghb_2",
          analysis_method_name_in_batch: nil,
          AnalysisMethodPolarity: nil,
          is_required: true,
          NameInStandLab: nil,
          ExcludedFromStatistic: true,
          material_type: mat.to_sym
        )
      end
    end



  end

  def reset_auto_increment(table_name, column: "id")
    result = ActiveRecord::Base.connection.execute(
      "SELECT COALESCE(MAX(#{column}), 0) + 1 AS next_id FROM #{table_name}"
    )
    next_id = result.first.first
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE #{table_name} AUTO_INCREMENT = #{next_id}"
    )
  end
end
