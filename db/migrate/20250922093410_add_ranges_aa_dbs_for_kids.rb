class AddRangesAaDbsForKids < ActiveRecord::Migration[7.0]
  def change     
    names = ["GABA", "Tau", "Sarc", "Orn", "hArg", "Cit", "bAla", "Val", "Tyr", "Trp", "Thr", "Ser", "Ala", "Arg", "Asn", "Asp", "Gln", "Glu", "Gly", "His", "Ile", "Pro", "Leu", "Lys", "Met", "Phe"]

    pattern = names.join("|")

    new_ranges = [
      { name: "GABA", from: 0.3, to: 1.4 },
      { name: "Tau", from: 93.0, to: 317.0 },
      { name: "Sarc", from: 0.5, to: 4.3 },
      { name: "Orn", from: 35.1, to: 132.7 },
      { name: "hArg", from: 0.3, to: 1.7 },
      { name: "Cit", from: 9.7, to: 31.1 },
      { name: "bAla", from: 2.8, to: 13.9 },
      { name: "Val", from: 73.2, to: 253.9 },
      { name: "Tyr", from: 24.6, to: 91.5 },
      { name: "Trp", from: 12.8, to: 41.2 },
      { name: "Thr", from: 37.1, to: 139.2 },
      { name: "Ser", from: 98.9, to: 302.2 },
      { name: "Ala", from: 107.0, to: 419.4 },
      { name: "Arg", from: 5.9, to: 70.6 },
      { name: "Asn", from: 28.9, to: 71.6 },
      { name: "Asp", from: 22.9, to: 152.6 },
      { name: "Gln", from: 234.0, to: 613.9 },
      { name: "Glu", from: 98.7, to: 215.6 },
      { name: "Gly", from: 135.4, to: 381.2 },
      { name: "His", from: 27.0, to: 96.6 },
      { name: "Ile", from: 19.5, to: 92.3 },
      { name: "Pro", from: 55.9, to: 240.7 },
      { name: "Leu", from: 38.2, to: 150.7 },
      { name: "Lys", from: 49.4, to: 153.9 },
      { name: "Met", from: 7.8, to: 30.3 },
      { name: "Phe", from: 21.7, to: 70.8 }
    ]

    ActiveRecord::Base.transaction do
      begin
        AnalyteRange.includes(:analyte).where(analyte: {material_type: 0, ProjectId: 3}).where("analyte.Name REGEXP ?", pattern).each do |ar|
          ar_dup = ar.dup
          ar.update!(AgeFromInMonths: 216, AgeToInMonths: 1800)  # dorosły
          puts "#{ar.analyte.Name} - updated"

          new_range = new_ranges.find{|n| n[:name] == ar.analyte.Name.gsub(/[^a-zA-Z]/, '')}
          raise ActiveRecord::Rollback if new_range.nil?
          ar_dup.assign_attributes(Name: "Dzieci", AgeFromInMonths: 0, AgeToInMonths: 216, Min: new_range[:from], Max: new_range[:to])
          ar_dup.save!
          puts "#{ar_dup.analyte.Name} - saved"
        end
      rescue StandardError => e
        pp e
        raise ActiveRecord::Rollback
      end
    end

  end
end
