module Notifications
  # Ustala instytucję próbki oraz rodzinę szablonu powiadomienia (:toxo | :lab).
  #
  # Dla próbki zarejestrowanej instytucję wyznacza kontraktor pacjenta.
  # Dla próbki niezarejestrowanej (pacjent wirtualny) instytucję wyznacza
  # kod próbki -> ReservedSampleCode -> Institution. NIGDY nie używamy do tego
  # ContractorId pacjenta wirtualnego (patrz spec §Clarifications).
  class TemplateResolver
    def self.institution_for(sample)
      new(sample).institution
    end

    def self.family_for(sample)
      new(sample).family
    end

    def initialize(sample)
      @sample = sample
    end

    def institution
      if registered?
        @sample.patient&.contractor&.institution
      else
        rsc = ReservedSampleCode.find_by(Code: @sample.Code)
        rsc&.institution
      end
    end

    def family
      inst = institution
      return :lab if inst.nil?

      inst.id.in?(V1::Common::TOXO_INSTITUTION_IDS) ? :toxo : :lab
    end

    private

    def registered?
      patient = @sample.patient
      patient.present? && !patient.IsVirtual
    end
  end
end
