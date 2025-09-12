class AddAnalytesWithMaterialType < ActiveRecord::Migration[7.0]

  def change
    ActiveRecord::Base.transaction do
      # add_column :Analytes, :material_type, :integer, null: false
      Analyte.reset_column_information

      migrate_material_types

      remove_column :AnalyteRanges, :MaterialType
      AnalyteRange.reset_column_information

      aa_pmr_updates
    end
  end

private

  def migrate_material_types
    # Get all analytes that have analyte_ranges with material types
    analytes_with_material_types = AnalyteRange.joins(:analyte)
                                               .where.not(MaterialType: nil)
                                               .order(:AnalyteId, :MaterialType)
                                               .group(:AnalyteId, :MaterialType)
                                               .pluck(:AnalyteId, :MaterialType)
                                               .group_by(&:first)

    puts "Found #{analytes_with_material_types.keys.count} analytes with material types"

    analytes_with_material_types.each do |analyte_id, material_type_pairs|
      original_analyte = Analyte.find(analyte_id)
      material_types = material_type_pairs.map(&:last).uniq.sort
      
      puts "Processing Analyte ID #{analyte_id} (#{original_analyte.Name}) with MaterialTypes: #{material_types.join(', ')}"

      # Set the first material type on the original analyte
      original_analyte.update!(material_type: material_types.first)

      # Create copies for additional material types
      material_types[1..-1].each do |material_type|
        new_analyte = original_analyte.dup
        new_analyte.material_type = material_type
        new_analyte.save!

        puts "  Created new analyte ID #{new_analyte.Id} for MaterialType #{material_type}"

        # Move the analyte ranges with this material_type to the new analyte
        moved_count = AnalyteRange.where(AnalyteId: analyte_id, MaterialType: material_type)
                                  .update_all(AnalyteId: new_analyte.Id)
        
        puts "    Moved #{moved_count} analyte ranges to new analyte"
      end
    end

    # Handle analytes without ranges - they keep material_type = 0 (default)
    analytes_without_ranges_count = Analyte.left_joins(:analyte_ranges)
                                          .where(analyte_ranges: { id: nil })
                                          .count
    
    puts "#{analytes_without_ranges_count} analytes without ranges will keep default MaterialType = 0"
    puts "Migration completed successfully!"
  end

  def aa_pmr_updates
    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Ala 1")                                                     
    analyte = original_analyte.dup                                                                        
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!                                                                                         
                                                                                                          
    men_analyte_range = AnalyteRange.create!(                                                             
      Name: "Mężczyzna",                                                                                  
      AgeFrom: 0,                                                                                         
      AgeTo: 150,                                                                                         
      Gender: 0,                                                                                          
      Min: 16,                                                                                            
      Max: 32,                                                                                            
      AnalyteId: analyte.Id,                                                                              
      AgeFromMonth: 0,                                                                                    
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 16,
      AcceptableMax: 32
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 16,
      Max: 32,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 16,
      AcceptableMax: 32
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Arg 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 0.0625, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 8,
      Max: 31,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 8,
      AcceptableMax: 31
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 8,
      Max: 31,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 8,
      AcceptableMax: 31
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Asn 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 4,
      Max: 13,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 4,
      AcceptableMax: 13
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 4,
      Max: 13,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 4,
      AcceptableMax: 13
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Asp 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Gln 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 330,
      Max: 630,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 330,
      AcceptableMax: 630
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 330,
      Max: 630,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 330,
      AcceptableMax: 630
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Glu 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Gly 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 5,
      Max: 20,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 5,
      AcceptableMax: 20
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 5,
      Max: 20,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 5,
      AcceptableMax: 20
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "His 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 7,
      Max: 24,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 7,
      AcceptableMax: 24
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 7,
      Max: 24,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 7,
      AcceptableMax: 24
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Ile 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 12,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 12
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 12,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 12
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Leu 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 5,
      Max: 22,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 5,
      AcceptableMax: 22
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 5,
      Max: 22,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 5,
      AcceptableMax: 22
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Lys 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 10,
      Max: 36,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 10,
      AcceptableMax: 36
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 10,
      Max: 36,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 10,
      AcceptableMax: 36
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Met 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 2,
      Max: 7,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 2,
      AcceptableMax: 7
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 2,
      Max: 7,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 2,
      AcceptableMax: 7
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Phe 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 6,
      Max: 20,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 6,
      AcceptableMax: 20
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 6,
      Max: 20,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 6,
      AcceptableMax: 20
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Pro 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Ser 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 18,
      Max: 66,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 18,
      AcceptableMax: 66
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 18,
      Max: 66,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 18,
      AcceptableMax: 66
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Thr 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 16,
      Max: 46,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 16,
      AcceptableMax: 46
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 16,
      Max: 46,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 16,
      AcceptableMax: 46
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Trp 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Tyr 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 5,
      Max: 23,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 5,
      AcceptableMax: 23
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 5,
      Max: 23,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 5,
      AcceptableMax: 23
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Val 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 8,
      Max: 30,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 8,
      AcceptableMax: 30
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 8,
      Max: 30,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 8,
      AcceptableMax: 30
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Cit 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "hArg 7")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 0.125, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 3,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 3
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 3,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 3
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Orn 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 10,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 10
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 10,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 10
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Sarc 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 0.125, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "bAla 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 0.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 5,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 5
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "Tau")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 1.25, CutoffMax: 1625, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 3,
      Max: 31,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 3,
      AcceptableMax: 31
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 3,
      Max: 31,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 3,
      AcceptableMax: 31
    )

    original_analyte = Analyte.where(ProjectId: 3).find_by(Name: "GABA 1")
    analyte = original_analyte.dup
    analyte.assign_attributes(CutoffMin: 0.025, CutoffMax: 5, material_type: 10)
    analyte.save!

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 6.2,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 6.2
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 6.2,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1.0,
      AcceptableMin: 0,
      AcceptableMax: 6.2
    )


    Analyte.where(ProjectId: 3).all.update_all(Unit: "µmol/L")


    
  end
end
