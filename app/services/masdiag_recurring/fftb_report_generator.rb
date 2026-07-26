module MasdiagRecurring
  class FftbReportGenerator < ApplicationService

    FFTB_INSTITUTION_ID = 83
    GENERIC_PATIENT_ID = 4798
    CSV_HEADERS = [
      "Sample Code",
      "Test",
      "Email (if blank it means not registered)",
      "Registration Date",
      "Lab Arrival Date",
      "Authorized At",
      "Expiration date",
      "Comment",
      "Comment 2",
      "Tests assigned",
      "Measurements"
    ].freeze

    def call
      codes = fetch_reserved_codes
      generic_codes = fetch_generic_codes
      not_used_codes = fetch_not_used_codes

      @rsc_lookup = build_rsc_lookup(codes + generic_codes + not_used_codes)

      handle_result(generate_csv_content(codes, generic_codes, not_used_codes))
    rescue StandardError => e
      Sentry.capture_exception(e)
      handle_error(e)
    end

    private

    def fetch_reserved_codes
      ReservedSampleCode.where(InstitutionId: FFTB_INSTITUTION_ID).where.not(material_handler: [:dbs_n2, :dbs_n4]).pluck(:Code)
    end

    def fetch_generic_codes
      ReservedSampleCode
        .where(InstitutionId: FFTB_INSTITUTION_ID)
        .where("comment LIKE ?", "%Generic Kits%")
        .pluck(:Code)
    end

    def fetch_not_used_codes
      rcodes = ReservedSampleCode.where(InstitutionId: FFTB_INSTITUTION_ID).pluck(:Code)
      scodes = rcodes - Sample.where(Code: rcodes).pluck(:Code)

      ReservedSampleCode.where(InstitutionId: FFTB_INSTITUTION_ID).where(Code: scodes)
        .where(expiry_date: Date.parse("2020-01-01")..Time.current)
        .pluck(:Code)
    end

    # Builds a hash { code => { exp_date:, tests: "...", reserved_tests_count: N } }
    # for all relevant codes in a single set of queries — eliminates N+1 from per-row lookups.
    def build_rsc_lookup(codes)
      all_codes = codes.uniq
      rscs = ReservedSampleCode
        .where(Code: all_codes)
        .includes(:projects)

      rscs.each_with_object({}) do |rsc, h|
        h[rsc.Code] = {
          exp_date: format_date(rsc.expiry_date),
          tests: rsc.projects_eng_names.join(", "),
          reserved_tests_count: rsc.projects.size
        }
      end
    end

    # Builds { code => measured_projects_count } from a batch of measurement rows.
    def build_measured_lookup(measurement_rows)
      measurement_rows.each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |row, h|
        h[row[0]] << row[7] # row[7] = ProjectId (see fetch_authorized_measurements)
      end.transform_values(&:size)
    end

    def generate_csv_content(codes, generic_codes, not_used_codes)
      io = StringIO.new
      io << csv_header

      append_qns_samples(io, codes)
      append_authorized_measurements(io, codes)
      append_unregistered_generic_kits(io, generic_codes)
      append_not_used_codes(io, not_used_codes)

      io.string
    end

    def csv_header
      CSV_HEADERS.join("\t") + "\n"
    end

    def append_qns_samples(io, codes)
      fetch_qns_samples(codes).each { |row| io << format_qns_row(row) }
    end

    def fetch_qns_samples(codes)
      Sample
        .where(soaking_degree_id: [4, 5])
        .where(Code: codes)
        .includes(:patient)
        .pluck(
          "Samples.Code",
          "Patients.email",
          "Samples.RegistrationDate",
          "Samples.AcceptanceDate",
          "Samples.soaking_degree_id",
          "Samples.Comment"
        )
    end

    def format_qns_row(data)
      code, email, registration_date, acceptance_date, _soaking_degree, comment = data
      rsc = @rsc_lookup[code] || {}

      [
        code,
        rsc[:tests],
        email,
        format_date(registration_date),
        format_date(acceptance_date),
        "",
        rsc[:exp_date],
        "QNS",
        comment.to_s.gsub(/[\t\n\r]/, '')
      ].join("\t") + "\n"
    end

    def append_authorized_measurements(io, codes)
      rows = fetch_authorized_measurements(codes)
      measured_lookup = build_measured_lookup(rows)

      rows.each { |row| io << format_measurement_row(row, measured_lookup) }
    end

    def fetch_authorized_measurements(codes)
      # Includes ProjectId (index 7) so build_measured_lookup can group without extra queries.
      Measurement
        .joins(sample: :patient)
        .joins(:project)
        .where(Samples: { Code: codes })
        .pluck(
          "Samples.Code",
          "Projects.eng_name",
          "Patients.email",
          "Measurements.AuthorizedAt",
          "Samples.RegistrationDate",
          "Samples.AcceptanceDate",
          "Samples.soaking_degree_id",
          "Measurements.ProjectId"
        )
    end

    def format_measurement_row(data, measured_lookup)
      code, test_name, email, authorized_at, registration_date, acceptance_date, _soaking_degree, _project_id = data
      rsc = @rsc_lookup[code] || {}

      [
        code,
        test_name,
        email,
        format_date(registration_date),
        format_date(acceptance_date),
        format_date(authorized_at),
        rsc[:exp_date],
        "",
        "",
        rsc[:reserved_tests_count],
        measured_lookup[code]
      ].join("\t") + "\n"
    end

    def append_not_used_codes(io, not_used_codes)
      fetch_unused_kits(not_used_codes).each { |row| io << format_unused_kit_row(row) }
    end

    def format_unused_kit_row(data)
      code, expiry_date = data
      rsc = @rsc_lookup[code] || {}

      [
        code,
        rsc[:tests],
        "",
        "",
        "",
        "",
        format_date(expiry_date),
        "UNUSED KIT"
      ].join("\t") + "\n"
    end

    def fetch_unused_kits(not_used_codes)
      ReservedSampleCode
        .where(Code: not_used_codes)
        .pluck(:Code, :expiry_date)
    end

    def append_unregistered_generic_kits(io, generic_codes)
      fetch_unregistered_generic_samples(generic_codes).each { |row| io << format_generic_kit_row(row) }
    end

    def fetch_unregistered_generic_samples(generic_codes)
      Sample
        .where(PatientId: GENERIC_PATIENT_ID)
        .where(Code: generic_codes)
        .includes(:patient)
        .pluck(
          "Samples.Code",
          "Patients.email",
          "Samples.RegistrationDate",
          "Samples.AcceptanceDate",
          "Samples.soaking_degree_id"
        )
    end

    def format_generic_kit_row(data)
      code, email, registration_date, acceptance_date, _soaking_degree = data
      rsc = @rsc_lookup[code] || {}

      [
        code,
        rsc[:tests],
        email,
        format_date(registration_date),
        format_date(acceptance_date),
        "",
        rsc[:exp_date],
        "NOT REGISTERED GENERIC KIT"
      ].join("\t") + "\n"
    end

    def format_date(date)
      date&.strftime("%Y-%m-%d") || ""
    rescue StandardError
      ""
    end

  end
end
