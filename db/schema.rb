# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_09_18_140000) do
  create_table "AnalyteRanges", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "Name", size: :long
    t.integer "AgeFrom", null: false
    t.integer "AgeTo", null: false
    t.integer "Gender"
    t.decimal "Min", precision: 18, scale: 2, null: false
    t.decimal "Max", precision: 18, scale: 2, null: false
    t.integer "AnalyteId"
    t.integer "AgeFromInMonths", null: false
    t.integer "AgeToInMonths", null: false
    t.decimal "Multiplier", precision: 18, scale: 2, null: false
    t.decimal "AcceptableMin", precision: 18, scale: 2
    t.decimal "AcceptableMax", precision: 18, scale: 2
    t.index ["AnalyteId"], name: "IX_AnalyteId"
  end

  create_table "AnalyteResults", primary_key: ["ResultId", "AnalyteId"], charset: "utf8", force: :cascade do |t|
    t.integer "ResultId", null: false
    t.integer "AnalyteId", null: false
    t.decimal "Value", precision: 20, scale: 4, null: false
    t.text "Unit", size: :long
    t.integer "Result_MeasurementId"
    t.decimal "MeasuredValue", precision: 18, scale: 5, null: false
    t.index ["AnalyteId"], name: "IX_AnalyteId"
    t.index ["Result_MeasurementId"], name: "IX_Result_MeasurementId"
  end

  create_table "Analytes", primary_key: "Id", id: :integer, charset: "utf8", collation: "utf8_polish_ci", options: "ENGINE=InnoDB ROW_FORMAT=COMPACT", force: :cascade do |t|
    t.text "Name", size: :long, null: false, collation: "utf8_general_ci"
    t.integer "ProjectId", null: false
    t.boolean "IsCalculatedFromOthers", null: false
    t.decimal "CutoffMin", precision: 11, scale: 4
    t.decimal "CutoffMax", precision: 11, scale: 4
    t.text "Unit", size: :long
    t.text "NameInReport", size: :long
    t.text "NameInAPI", size: :long
    t.string "analysis_method_name_in_batch"
    t.text "AnalysisMethodPolarity", size: :long
    t.boolean "is_required", null: false
    t.text "NameInStandLab", size: :tiny
    t.boolean "ExcludedFromStatistic", null: false
    t.integer "material_type", null: false
    t.index ["ProjectId"], name: "IX_ProjectId"
  end

  create_table "CeraSamples", primary_key: "Id", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "SampleId", null: false
    t.boolean "BadQuality", null: false
    t.boolean "IsResultSentToCera", null: false
    t.datetime "ResultSentToCeraDate", precision: nil
    t.text "CeraType", size: :long
    t.text "CheckupJson", size: :long
    t.integer "PatientId"
    t.integer "CsvFileId"
    t.boolean "IsResultSendInCsvFile", null: false
    t.datetime "CeraTestedAt", precision: nil
    t.integer "MasdiagProjectId", null: false
    t.index ["PatientId"], name: "IX_PatientId"
    t.index ["SampleId"], name: "IX_SampleId"
  end

  create_table "Contractors", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "Name", size: :long
    t.text "Address", size: :long
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "first_name", collation: "utf8_polish_ci"
    t.string "last_name", collation: "utf8_polish_ci"
    t.string "nip"
    t.boolean "approved", default: false, null: false
    t.boolean "are_notifications_enabled", default: false, null: false
    t.integer "type_of_contractor", default: 0, null: false
    t.integer "institution_id"
    t.integer "agent_id"
    t.string "phone"
    t.boolean "invalid_first_or_last_name", null: false
    t.boolean "patient_is_orderer", null: false
    t.boolean "is_super_contractor", default: false
    t.boolean "can_add_samples", default: true
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "confirmation_token"
    t.string "unconfirmed_email"
    t.integer "creator_id"
    t.string "locale", default: "pl", null: false
    t.boolean "allow_sample_acceptance_notifications", default: true, null: false
    t.boolean "allow_sample_rejection_notifications", default: true, null: false
    t.boolean "allow_result_notifications", default: true, null: false
    t.boolean "allow_sample_registration_notifications", default: true, null: false
    t.index ["agent_id"], name: "index_Contractors_on_agent_id"
    t.index ["email"], name: "index_Contractors_on_email", unique: true
    t.index ["institution_id"], name: "index_Contractors_on_institution_id"
    t.index ["locale"], name: "index_Contractors_on_locale"
    t.index ["reset_password_token"], name: "index_Contractors_on_reset_password_token", unique: true
  end

  create_table "FileDatas", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "FileType", size: :long
    t.integer "FileLength", null: false
    t.binary "FileContent", size: :long
    t.integer "ProtocolId", null: false
    t.index ["ProtocolId"], name: "IX_ProtocolId"
  end

  create_table "GaSamples", primary_key: "Id", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "SampleId", null: false
    t.integer "PatientId", null: false
    t.boolean "BadQuality", null: false
    t.boolean "IsResultSent", null: false
    t.datetime "ResultSentDate", precision: nil
    t.text "Type", size: :long
    t.integer "MasdiagProjectId", null: false
    t.datetime "SampleCollectedAt", precision: nil
    t.text "CheckupJson", size: :long
    t.index ["PatientId"], name: "IX_PatientId"
    t.index ["SampleId"], name: "IX_SampleId"
  end

  create_table "LogMessages", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "Message", size: :long
    t.text "SecondMessage", size: :long
    t.text "Stacktrace", size: :long
    t.text "SecondStacktrace", size: :long
    t.datetime "Date", precision: nil, null: false
    t.integer "UserId"
    t.integer "Type", null: false
    t.index ["UserId"], name: "IX_UserId"
  end

  create_table "Measurements", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.integer "SampleId", null: false
    t.integer "ProjectId", null: false
    t.integer "ResultId"
    t.boolean "IsRepeat", default: false, null: false
    t.integer "Status", null: false
    t.datetime "MeasureDate", precision: nil
    t.boolean "IsValid", default: false, null: false
    t.text "LabCode", size: :long
    t.integer "CreatedById"
    t.datetime "CreatedAt", precision: nil
    t.integer "ModifiedById"
    t.datetime "ModifiedAt", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "AuthorizedById"
    t.datetime "AuthorizedAt", precision: nil
    t.datetime "CuttedAt", precision: nil
    t.text "selected_analytes"
    t.integer "InstrumentId"
    t.integer "MaterialType", default: 0, null: false
    t.index ["AuthorizedById"], name: "IX_AuthorizedById"
    t.index ["CreatedById"], name: "IX_CreatedById"
    t.index ["InstrumentId"], name: "IX_InstrumentId"
    t.index ["ModifiedById"], name: "IX_ModifiedById"
    t.index ["ProjectId"], name: "IX_ProjectId"
    t.index ["SampleId"], name: "IX_SampleId"
  end

  create_table "Multiplexes", primary_key: "Id", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.text "Name", size: :tiny
  end

  create_table "Patients", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.datetime "RegistrationDate", precision: nil, null: false
    t.text "FirstName", size: :long, null: false
    t.text "LastName", size: :long, null: false
    t.text "Pesel", size: :long
    t.datetime "BirthDate", precision: nil, null: false
    t.integer "Gender", null: false
    t.integer "ContractorId", null: false
    t.integer "CreatedById"
    t.datetime "CreatedAt", precision: nil
    t.integer "ModifiedById"
    t.datetime "ModifiedAt", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "email"
    t.string "phone"
    t.boolean "is_foreigner", default: false, null: false
    t.boolean "approve1", default: false
    t.boolean "approve2", default: false
    t.boolean "approve3", default: false
    t.string "language", default: "pl", null: false
    t.boolean "approve_personal_data", default: false
    t.boolean "IsVirtual", null: false
    t.boolean "send_results_on_mail", default: false, null: false
    t.string "body_weight"
    t.string "body_height"
    t.integer "id_document"
    t.string "id_number"
    t.index ["ContractorId"], name: "IX_ContractorId"
    t.index ["CreatedById"], name: "IX_CreatedById"
    t.index ["ModifiedById"], name: "IX_ModifiedById"
  end

  create_table "PlateMeasurements", primary_key: "MeasurementId", id: :integer, default: nil, charset: "utf8", force: :cascade do |t|
    t.integer "PlatePosition", null: false
    t.integer "PlateId", null: false
    t.integer "CreatedById", null: false
    t.datetime "CreatedAt", precision: nil, null: false
    t.index ["CreatedById"], name: "IX_CreatedById"
    t.index ["PlateId", "MeasurementId"], name: "IX_PlateMeasurement_PlateMeasurement", unique: true
  end

  create_table "Plates", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.integer "ProjectId", null: false
    t.datetime "RegistrationDate", precision: nil, null: false
    t.text "Code", size: :long, null: false
    t.boolean "IsValid", null: false
    t.integer "CreatedById", null: false
    t.datetime "CreatedAt", precision: nil, null: false
    t.integer "ModifiedById"
    t.datetime "ModifiedAt", precision: nil
    t.boolean "ResultWasAdded", null: false
    t.datetime "ResultWasAddedDate", precision: nil
    t.boolean "IsPartOfMultiplex", null: false
    t.integer "MultiplexId"
    t.integer "Suffix", null: false
    t.binary "qc_report_file", size: :long
    t.index ["CreatedById"], name: "IX_CreatedById"
    t.index ["ModifiedById"], name: "IX_ModifiedById"
    t.index ["MultiplexId"], name: "IX_MultiplexId"
  end

  create_table "Project_translations", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "Name"
    t.text "Description"
    t.text "survey_description"
    t.text "PdfNameOfAnalysis"
    t.text "PdfDescription"
    t.text "product_name_in_invoice"
    t.string "locale", null: false
    t.integer "project_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["locale"], name: "index_project_translations_on_locale"
    t.index ["project_id", "locale"], name: "index_project_translations_on_project_id_and_locale", unique: true
    t.index ["project_id"], name: "index_project_translations_on_project_id"
  end

  create_table "Projects", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "Name", size: :long, null: false
    t.text "Description", size: :long
    t.boolean "WithCutter", null: false
    t.integer "PlateDimensionX", null: false
    t.integer "PlateDimensionY", null: false
    t.text "Prefix", size: :long
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_blocked_online", default: false, null: false
    t.text "survey_description"
    t.text "PdfNameOfAnalysis", size: :long
    t.text "PdfDescription", size: :long
    t.text "product_name_in_invoice"
    t.string "pkwiu_in_invoice"
    t.decimal "brutto_price", precision: 6, scale: 2
    t.text "FinalProtocoleHeader", size: :long
    t.string "responsible_person_email"
    t.boolean "has_selectable_analytes"
    t.decimal "InjectionVolume", precision: 4, scale: 1, null: false
    t.string "eng_name"
    t.boolean "is_active", default: true, null: false
  end

  create_table "ProtocolSamples", primary_key: ["Protocol_Id", "Sample_Id"], charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "Protocol_Id", null: false
    t.integer "Sample_Id", null: false
    t.index ["Protocol_Id"], name: "IX_Protocol_Id"
    t.index ["Sample_Id"], name: "IX_Sample_Id"
  end

  create_table "Protocols", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "Name", size: :long
    t.integer "CreatedById", null: false
    t.datetime "CreatedAt", precision: nil
    t.integer "Kind", null: false
    t.integer "ProjectId"
    t.integer "SamplesCount", null: false
    t.index ["CreatedById"], name: "IX_CreatedById"
    t.index ["ProjectId"], name: "IX_ProjectId"
  end

  create_table "ReservedSampleCodes", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.string "Code", limit: 50
    t.datetime "CreatedAt", precision: nil, null: false
    t.integer "CreatedById"
    t.integer "InstitutionId"
    t.boolean "IsRetailSale", null: false
    t.integer "SerialNumber"
    t.text "ExtendedSerialNumber", size: :long
    t.string "OwnerEmail"
    t.integer "package_type"
    t.datetime "expiry_date", precision: nil
    t.integer "reserved_by_contractor_id"
    t.string "lot"
    t.string "ref"
    t.bigint "package_id"
    t.integer "parent_id"
    t.text "comment"
    t.datetime "assignment_date", precision: nil
    t.integer "MaterialType", default: 0, null: false
    t.integer "material_handler", default: 0, null: false
    t.index ["Code"], name: "index_ReservedSampleCodes_on_Code", unique: true
    t.index ["CreatedById"], name: "IX_CreatedById"
    t.index ["InstitutionId"], name: "IX_InstitutionId"
    t.index ["package_id"], name: "index_ReservedSampleCodes_on_package_id"
  end

  create_table "Results", primary_key: "MeasurementId", id: :integer, default: nil, charset: "utf8", force: :cascade do |t|
    t.datetime "ImportDate", precision: nil, null: false
    t.text "Description", size: :long
    t.text "PlateCode", size: :long
    t.boolean "IsValid", null: false
    t.integer "ImportUserId", null: false
    t.index ["ImportUserId"], name: "IX_ImportUserId"
    t.index ["MeasurementId"], name: "IX_MeasurementId"
  end

  create_table "Samples", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.string "Code", limit: 50, null: false
    t.text "ProtocolName", size: :long
    t.boolean "IsControlSample", default: false, null: false
    t.boolean "IsWrongRegistration", default: false, null: false
    t.boolean "IsSentBack", default: false, null: false
    t.datetime "SentBackDate", precision: nil
    t.text "Description", size: :long
    t.datetime "RegistrationDate", precision: nil
    t.boolean "IsValid", default: true, null: false
    t.integer "PatientId"
    t.integer "UserId"
    t.boolean "IsAuthWithoutResult", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "payment_status"
    t.datetime "AcceptanceDate", precision: nil
    t.string "access_hash"
    t.datetime "sample_collection_date", precision: nil
    t.integer "soaking_degree_id"
    t.boolean "WasWrongRegistration", null: false
    t.integer "MaterialType", null: false
    t.integer "SampleStatus", null: false
    t.integer "SampleState", null: false
    t.text "Comment", size: :long
    t.datetime "CancellationDate", precision: nil
    t.datetime "ArchivingDate", precision: nil
    t.integer "WrongRegistrationStatus", null: false
    t.integer "CancelledById"
    t.datetime "UtilizationDate", precision: nil
    t.text "Lot", size: :tiny
    t.text "Level", size: :tiny
    t.text "selected_tests"
    t.text "clinical_info"
    t.integer "reserved_sample_code_id"
    t.datetime "dispatch_date"
    t.integer "post_examination_procedure", default: 0, null: false
    t.integer "infectious_risk", default: 0, null: false
    t.integer "execution_mode", default: 0, null: false
    t.index ["CancelledById"], name: "IX_CancelledById"
    t.index ["Code"], name: "IX_Code"
    t.index ["PatientId"], name: "IX_PatientId"
    t.index ["UserId"], name: "IX_UserId"
    t.index ["reserved_sample_code_id"], name: "index_Samples_on_reserved_sample_code_id"
    t.index ["soaking_degree_id"], name: "IX_soaking_degree_id"
  end

  create_table "SamplesToCsvQueues", primary_key: "ProtocolId", id: :integer, default: nil, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.boolean "IsDone", null: false
    t.text "SampleIds", size: :long
    t.index ["ProtocolId"], name: "IX_ProtocolId"
  end

  create_table "Users", primary_key: "Id", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "Login", size: :long, null: false
    t.text "Password", size: :long, null: false
    t.text "Salt", size: :long, null: false
    t.text "FirstName", size: :long
    t.text "LastName", size: :long
    t.boolean "IsActive", null: false
    t.integer "Role", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "type"
    t.text "Description", size: :long
    t.datetime "LastPasswordChangeAt", precision: nil
    t.datetime "PasswordChangeRevokedAt", precision: nil
    t.datetime "password_changed_at", precision: nil
    t.text "LastSelectedCertLabel", size: :long
    t.boolean "HasSmartCard", null: false
    t.text "TokenSerialNumber", size: :long
    t.index ["password_changed_at"], name: "index_Users_on_password_changed_at"
    t.index ["reset_password_token"], name: "index_Users_on_reset_password_token", unique: true
  end

  create_table "__MigrationHistory", primary_key: "MigrationId", id: { type: :string, limit: 150 }, charset: "utf8", force: :cascade do |t|
    t.string "ContextKey", limit: 300, null: false
    t.binary "Model", size: :long, null: false
    t.string "ProductVersion", limit: 32, null: false
  end

  create_table "active_storage_attachments", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agents", id: :integer, charset: "utf8", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "type"
    t.string "first_name"
    t.string "last_name"
    t.text "slave_agents"
    t.integer "master_agent"
    t.boolean "allow_institution_creation", default: false
    t.text "summary"
    t.datetime "summary_updated_at", precision: nil
    t.datetime "start_of_activity_date", precision: nil
    t.integer "super_contractor_id"
    t.index ["email"], name: "index_agents_on_email", unique: true
    t.index ["reset_password_token"], name: "index_agents_on_reset_password_token", unique: true
  end

  create_table "answers", id: :integer, charset: "utf8", force: :cascade do |t|
    t.integer "option_id"
    t.integer "survey_question_id"
    t.integer "Sample_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "other_field_text"
    t.index ["Sample_id"], name: "index_answers_on_Sample_id"
    t.index ["option_id"], name: "index_answers_on_option_id"
    t.index ["survey_question_id"], name: "index_answers_on_survey_question_id"
  end

  create_table "api_accounts", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.integer "contractor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "settings"
    t.text "settings_ciphertext"
    t.string "language", default: "pl", null: false
    t.index ["contractor_id"], name: "fk_rails_8f4a850bff"
  end

  create_table "audits", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at", precision: nil
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "config_entries", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "key", null: false, collation: "utf8_general_ci"
    t.text "json", size: :long
    t.string "config_type", collation: "utf8_general_ci"
    t.index ["key"], name: "IX_key", unique: true
  end

  create_table "csv_files", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.text "filename", size: :long
    t.text "content_type", size: :long
    t.integer "file_size", null: false
    t.binary "file_contents", size: :medium
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "samples_count", null: false
    t.text "sample_ids", size: :long
  end

  create_table "db_files", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.text "file_type", size: :long
    t.integer "file_length", null: false
    t.binary "file_content", size: :medium
    t.integer "fileable_id", null: false
    t.index ["fileable_id"], name: "IX_fileable_id"
  end

  create_table "delayed_jobs", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "discounts_invoices", id: :integer, charset: "utf8", force: :cascade do |t|
    t.integer "invoice_id"
    t.integer "discount_id"
  end

  create_table "fileables", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
  end

  create_table "hl7_imports", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "measurement_id"
    t.string "s3_key", null: false
    t.string "s3_bucket"
    t.string "s3_etag"
    t.integer "file_size"
    t.string "control_id"
    t.string "message_type"
    t.datetime "message_datetime"
    t.string "sending_application"
    t.string "sending_facility"
    t.string "external_order_id"
    t.string "hl7_test_code"
    t.string "kit_code_extracted"
    t.integer "status", default: 0, null: false
    t.datetime "processed_at"
    t.text "error_message"
    t.text "processing_stats"
    t.integer "retry_count", default: 0
    t.datetime "last_retry_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_hl7_imports_on_created_at"
    t.index ["kit_code_extracted"], name: "index_hl7_imports_on_kit_code_extracted"
    t.index ["measurement_id"], name: "index_hl7_imports_on_measurement_id", unique: true
    t.index ["s3_key"], name: "index_hl7_imports_on_s3_key", unique: true
    t.index ["status"], name: "index_hl7_imports_on_status"
  end

  create_table "institution_order_components", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "institution_order_id", null: false
    t.integer "test_transaction_id"
    t.integer "project_id"
    t.integer "package_type"
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "cost"
    t.text "retrieved_institution_tests"
    t.float "vat_rate"
    t.boolean "shipment_component", default: false
    t.integer "product_id"
    t.index ["institution_order_id"], name: "index_institution_order_components_on_institution_order_id"
    t.index ["project_id"], name: "index_institution_order_components_on_project_id"
    t.index ["test_transaction_id"], name: "index_institution_order_components_on_test_transaction_id"
  end

  create_table "institution_orders", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "contractor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "total_cost"
    t.integer "test_amount"
    t.boolean "is_paid", default: false
    t.datetime "payment_date", precision: nil
    t.string "confirmation_token"
    t.integer "status"
    t.boolean "rejected_sample_order", default: false
    t.string "order_number"
    t.datetime "confirmed_at", precision: nil
    t.string "company_for_shipment"
    t.string "shipment_street"
    t.string "shipment_postal_code"
    t.string "shipment_city"
    t.string "contact_person_name"
    t.string "contact_person_phone"
    t.string "ifirma_fv_id"
    t.string "ifirma_proforma_id"
    t.text "retrieved_samples"
    t.datetime "was_paid_on", precision: nil
    t.string "type", null: false
    t.datetime "confirmation_time", precision: nil
    t.index ["contractor_id"], name: "index_institution_orders_on_contractor_id"
  end

  create_table "institution_tests", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "institution_id", null: false
    t.integer "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expiry_date", precision: nil
    t.integer "test_transaction_id"
    t.boolean "used", default: false
    t.integer "used_by_test_transaction_id"
    t.boolean "duplicate", default: false
    t.index ["institution_id"], name: "index_institution_tests_on_institution_id"
    t.index ["project_id"], name: "index_institution_tests_on_project_id"
  end

  create_table "institutions", id: :integer, charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.text "address"
    t.string "nip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "allow_patient_email", default: false, null: false
    t.boolean "has_approve_messages_for_patients", default: false, null: false
    t.boolean "has_payment_status_in_samples", default: false, null: false
    t.binary "logo_file", size: :medium
    t.string "krs"
    t.string "regon"
    t.boolean "has_disabled_invoices", default: false, null: false
    t.boolean "approve_contractor_after_registration", default: false, null: false
    t.string "email"
    t.integer "created_by_agent_id"
    t.boolean "wants_summary_of_performed_samples"
    t.text "footer_phone_and_email", size: :long
    t.text "patient_email_template_body"
    t.text "contractor_email_template_body"
    t.binary "inivitation_jpg_image", size: :medium
    t.binary "email_attachment_pdf", size: :medium
    t.text "custom_cbx_text_in_sample_form"
    t.string "smtp_settings_name"
    t.string "smtp_email"
    t.integer "test_alert_treshold"
    t.text "shipping_address"
    t.boolean "terms_accepted"
    t.datetime "terms_accepted_at", precision: nil
    t.boolean "auto_test_charge"
    t.boolean "electronic_invoice_acceptance"
    t.datetime "electronic_invoice_accepted_at", precision: nil
    t.string "terms_version"
    t.string "street"
    t.string "postal_code"
    t.string "city"
    t.string "company_for_shipments"
    t.string "shipment_street"
    t.string "shipment_postal_code"
    t.string "shipment_city"
    t.string "kind", default: "Institution", null: false
    t.string "email_for_results"
    t.string "assigned_masdiag_bban", default: "09 2490 0005 0000 4530 4006 9262"
    t.integer "days_for_payment"
    t.string "email_for_notifications"
    t.string "short_name"
    t.index ["created_by_agent_id"], name: "fk_rails_4adfc629f3"
  end

  create_table "instruments", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.text "name", size: :long
    t.text "short_name", size: :long
  end

  create_table "invoice_components", id: :integer, charset: "utf8", force: :cascade do |t|
    t.integer "lp"
    t.text "product_name"
    t.string "pkwiu"
    t.decimal "unit_price", precision: 9, scale: 2
    t.decimal "netto_value", precision: 9, scale: 2
    t.decimal "vat", precision: 4, scale: 2
    t.decimal "vat_value", precision: 8, scale: 2
    t.decimal "brutto_value", precision: 9, scale: 2
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "invoice_id"
    t.decimal "amount", precision: 8, scale: 2
    t.text "measurements_properties"
    t.integer "contractor_id"
    t.integer "institution_id"
    t.string "currency", default: "PLN"
    t.bigint "test_id"
    t.index ["contractor_id"], name: "index_invoice_components_on_contractor_id"
    t.index ["institution_id"], name: "fk_rails_49b9961858"
    t.index ["invoice_id"], name: "index_invoice_components_on_invoice_id"
    t.index ["test_id"], name: "fk_rails_0c513b6435"
  end

  create_table "invoices", id: :integer, charset: "utf8", force: :cascade do |t|
    t.string "number"
    t.date "date_of_invoice"
    t.date "date_of_sale"
    t.string "payment_method"
    t.text "invoice_summary"
    t.decimal "netto_value_sum", precision: 9, scale: 2
    t.decimal "vat_value_sum", precision: 8, scale: 2
    t.decimal "brutto_value_sum", precision: 9, scale: 2
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "institution_id"
    t.binary "xlsx_file", size: :medium
    t.binary "summary_of_performed_samples_file", size: :medium
    t.boolean "was_sent_by_mail"
    t.datetime "when_was_sent_by_mail", precision: nil
    t.binary "pdf_file", size: :medium
    t.integer "institution_order_id"
    t.string "pdf_filename"
    t.string "ifirma_invoice_signature"
    t.date "issue_date"
    t.date "date_of_payment"
    t.boolean "is_paid", default: false
    t.date "was_paid_on"
    t.integer "status", limit: 1, default: 0
    t.integer "ifirma_fv_id"
    t.index ["institution_id"], name: "index_invoices_on_institution_id"
  end

  create_table "kits", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "shop_id"
    t.string "tag_content"
    t.integer "sample_id"
    t.boolean "is_registered"
    t.text "shop_product_json"
    t.text "own_product_json"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "shop_order_id"
    t.integer "reserved_sample_code_id"
    t.index ["reserved_sample_code_id"], name: "fk_rails_e4fb39b9d6"
    t.index ["sample_id"], name: "fk_rails_67e1b811dd"
    t.index ["shop_order_id"], name: "index_kits_on_shop_order_id"
  end

  create_table "laboratory_books", id: :integer, charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.date "begin_date"
    t.date "end_date"
    t.text "measurement_properties"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.binary "xlsx_file", size: :medium
  end

  create_table "labsample_releases", charset: "utf8mb4", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "version", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["version"], name: "index_labsample_releases_on_version", unique: true
  end

  create_table "measurement_summaries", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "name"
    t.integer "institution_id", null: false
    t.date "from_date"
    t.date "to_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id"], name: "index_measurement_summaries_on_institution_id"
  end

  create_table "measurement_summary_items", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.bigint "measurement_summary_id", null: false
    t.integer "measurement_id", null: false
    t.integer "sample_id", null: false
    t.integer "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "test_variant"
    t.bigint "test_id"
    t.index ["measurement_id"], name: "index_measurement_summary_items_on_measurement_id"
    t.index ["measurement_summary_id"], name: "index_measurement_summary_items_on_measurement_summary_id"
    t.index ["project_id"], name: "index_measurement_summary_items_on_project_id"
    t.index ["sample_id"], name: "index_measurement_summary_items_on_sample_id"
    t.index ["test_id"], name: "index_measurement_summary_items_on_test_id"
  end

  create_table "mobility_string_translations", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.string "value"
    t.string "translatable_type"
    t.bigint "translatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "index_mobility_string_translations_on_translatable_attribute"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "index_mobility_string_translations_on_keys", unique: true
    t.index ["translatable_type", "key", "value", "locale"], name: "index_mobility_string_translations_on_query_keys"
  end

  create_table "mobility_text_translations", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.text "value"
    t.string "translatable_type"
    t.bigint "translatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "index_mobility_text_translations_on_translatable_attribute"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "index_mobility_text_translations_on_keys", unique: true
  end

  create_table "notes", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.text "description"
    t.string "key"
    t.string "subject_type", null: false
    t.bigint "subject_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["key"], name: "index_notes_on_key"
    t.index ["subject_type", "subject_id"], name: "index_notes_on_subject_type_and_subject_id"
  end

  create_table "old_passwords", id: :integer, charset: "utf8", force: :cascade do |t|
    t.string "encrypted_password", null: false
    t.string "password_archivable_type", null: false
    t.integer "password_archivable_id", null: false
    t.string "password_salt"
    t.datetime "created_at", precision: nil
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable"
  end

  create_table "online_files", primary_key: "measurement_id", id: :integer, default: nil, charset: "utf8", force: :cascade do |t|
    t.text "filename", size: :long
    t.text "content_type", size: :long
    t.integer "file_size", null: false
    t.binary "file_contents", size: :long
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_notification_send", default: false, null: false
    t.boolean "is_patient_notification_send", default: false, null: false
    t.string "password"
    t.datetime "when_notification_send", precision: nil
    t.datetime "when_patient_notification_send", precision: nil
    t.integer "encrypted_file_size", null: false
    t.binary "encrypted_file_contents", size: :long
    t.index ["measurement_id"], name: "IX_measurement_id"
  end

  create_table "option_translations", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "option_text"
    t.string "locale", null: false
    t.integer "option_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["locale"], name: "index_option_translations_on_locale"
    t.index ["option_id", "locale"], name: "index_option_translations_on_option_id_and_locale", unique: true
    t.index ["option_id"], name: "index_option_translations_on_option_id"
  end

  create_table "options", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "option_text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "has_second_level_questions", default: false, null: false
    t.boolean "is_other_option", default: false, null: false
  end

  create_table "options_survey_questions", id: false, charset: "utf8", force: :cascade do |t|
    t.integer "survey_question_id"
    t.integer "option_id"
    t.index ["survey_question_id", "option_id"], name: "sur_quest_opt_index"
  end

  create_table "order_panel_delayed_jobs", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "order_panel_users", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_order_panel_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_order_panel_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_order_panel_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_order_panel_users_on_uid_and_provider", unique: true
  end

  create_table "packages", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "serial_number"
    t.string "extended_serial_number"
    t.datetime "expiry_date", precision: nil
    t.bigint "product_id", null: false
    t.bigint "production_order_id"
    t.bigint "stock_room_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "shipment_id"
    t.text "comment"
    t.datetime "scan_time", precision: nil
    t.bigint "shop_order_id"
    t.index ["product_id"], name: "fk_rails_414e4ba737"
    t.index ["production_order_id"], name: "fk_rails_7381ce65c8"
    t.index ["shop_order_id"], name: "index_packages_on_shop_order_id"
    t.index ["stock_room_id"], name: "fk_rails_e067235a3b"
  end

  create_table "production_orders", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "lot"
    t.datetime "packages_expiry_date", precision: nil
    t.integer "packages_count"
    t.bigint "product_id"
    t.bigint "stock_room_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "comment"
    t.integer "sample_code_char_count", default: 5, null: false
    t.index ["product_id"], name: "fk_rails_b45fb21cdc"
    t.index ["stock_room_id"], name: "fk_rails_b081d45c17"
  end

  create_table "products", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "name"
    t.string "ref"
    t.integer "type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "capacity"
    t.integer "material_type", default: 0, null: false
    t.integer "material_handler", default: 0, null: false
  end

  create_table "quality_control_components", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.decimal "mean", precision: 9, scale: 3
    t.decimal "two_sd_value", precision: 9, scale: 3
    t.decimal "three_sd_value", precision: 9, scale: 3
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "analyte_id"
    t.integer "quality_control_id"
    t.text "charts_data"
    t.text "two_sd_exceedance_properties"
    t.text "three_sd_exceedance_properties"
    t.index ["analyte_id"], name: "index_quality_control_components_on_analyte_id"
    t.index ["quality_control_id"], name: "index_quality_control_components_on_quality_control_id"
  end

  create_table "quality_controls", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "name"
    t.date "preperiod_begin"
    t.date "preperiod_end"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sample_id"
    t.integer "project_id"
    t.integer "preperiod_measurements_count"
    t.integer "working_period_measurements_count"
    t.integer "previous_sample_id"
    t.date "tested_samples_date"
    t.integer "meas_count_for_statistic"
    t.index ["project_id"], name: "index_quality_controls_on_project_id"
    t.index ["sample_id"], name: "index_quality_controls_on_sample_id"
  end

  create_table "rejestracja2_delayed_jobs", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "rejestracja2_delayed_jobs_priority"
  end

  create_table "reserved_tests", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "project_id"
    t.integer "reserved_sample_code_id"
    t.index ["project_id", "reserved_sample_code_id"], name: "index_reserved_tests_on_project_id_and_reserved_sample_code_id"
  end

  create_table "result_sending_events", id: :integer, default: nil, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "measurement_id"
    t.integer "sample_id", null: false
    t.datetime "sent_date", precision: nil
    t.integer "sent_through"
    t.text "recipient", size: :long
    t.text "address", size: :long
    t.text "result_text_representation"
    t.index ["id"], name: "IX_id"
    t.index ["measurement_id"], name: "IX_measurement_id"
    t.index ["sample_id"], name: "IX_sample_id"
  end

  create_table "scanned_docs", charset: "utf8mb4", force: :cascade do |t|
    t.string "source_filename", null: false
    t.string "page_checksum", limit: 64, null: false
    t.string "document_key"
    t.integer "status", default: 0, null: false
    t.string "source", default: "scan_watcher", null: false
    t.integer "sample_id"
    t.datetime "captured_at"
    t.datetime "received_at"
    t.datetime "ocr_started_at"
    t.datetime "transcribed_at"
    t.text "processing_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_checksum"], name: "index_scanned_docs_on_page_checksum", unique: true
    t.index ["sample_id"], name: "index_scanned_docs_on_sample_id"
    t.index ["status"], name: "index_scanned_docs_on_status"
  end

  create_table "sessions", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "contractor_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.string "token", null: false
    t.datetime "last_active_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contractor_id"], name: "index_sessions_on_contractor_id"
    t.index ["token"], name: "index_sessions_on_token", unique: true
  end

  create_table "shipments", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "shipmentable_id", null: false
    t.string "shipmentable_type", null: false
    t.string "shipping_company"
    t.string "waybill_number"
    t.string "company_name"
    t.string "shipping_street", null: false
    t.string "shipping_postal_code", null: false
    t.string "shipping_city", null: false
    t.string "contact_person_name"
    t.string "contact_person_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shipping_company_id"
    t.index ["shipmentable_type", "shipmentable_id"], name: "index_shipments_on_shipmentable_type_and_shipmentable_id"
  end

  create_table "shipping_companies", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "contract_signature"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_shipping_companies_on_name", unique: true
  end

  create_table "shop_orders", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "number"
    t.string "time_signature"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "snapshot_package_ids"
    t.text "kits"
    t.text "coupons"
    t.decimal "total_cost", precision: 7, scale: 2
    t.decimal "total_cost_with_coupons", precision: 7, scale: 2
    t.string "source", default: "wordpress"
  end

  create_table "shopify_order_deliveries", charset: "utf8mb4", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "webhook_id", null: false
    t.string "shopify_order_id", null: false
    t.string "event_type", default: "orders/paid", null: false
    t.text "payload", size: :medium, null: false
    t.integer "status", default: 0, null: false
    t.text "failure_reason"
    t.text "unmapped_product_ids"
    t.text "resolved_project_ids"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "shop_order_id"
    t.index ["shop_order_id"], name: "index_shopify_order_deliveries_on_shop_order_id"
    t.index ["shopify_order_id"], name: "index_shopify_order_deliveries_on_shopify_order_id"
    t.index ["status"], name: "index_shopify_order_deliveries_on_status"
    t.index ["webhook_id"], name: "index_shopify_order_deliveries_on_webhook_id", unique: true
  end

  create_table "soaking_degrees", id: :integer, charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.text "name", size: :long
    t.integer "sn", null: false
  end

  create_table "solid_queue_blocked_executions", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_scheduled_executions", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "stock_room_items", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.bigint "storagable_id"
    t.string "storagable_type"
    t.integer "capacity"
    t.integer "remaining_quantity"
    t.datetime "last_partial_consume_date", precision: nil
    t.datetime "date_in", precision: nil
    t.datetime "date_out", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "stock_room_id"
    t.index ["stock_room_id"], name: "index_stock_room_items_on_stock_room_id"
    t.index ["storagable_type", "storagable_id"], name: "index_stock_room_items_on_storagable_type_and_storagable_id"
  end

  create_table "stock_rooms", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "storage_delayed_jobs", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "survey_question_translations", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "question_text"
    t.string "locale", null: false
    t.integer "survey_question_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["locale"], name: "index_survey_question_translations_on_locale"
    t.index ["survey_question_id", "locale"], name: "index_340e754556c2d3a2f4860aa9e5bd1f9ca3a7cc5d", unique: true
    t.index ["survey_question_id"], name: "index_survey_question_translations_on_survey_question_id"
  end

  create_table "survey_questions", id: :integer, charset: "utf8", force: :cascade do |t|
    t.text "question_text"
    t.integer "Project_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "has_other_field"
    t.boolean "is_second_level_question", default: false, null: false
    t.boolean "is_required", default: false
    t.boolean "is_multichoice", default: false, null: false
    t.integer "position", default: 0, null: false
    t.index ["Project_id"], name: "index_survey_questions_on_Project_id"
  end

  create_table "survey_reports", id: :integer, charset: "utf8", force: :cascade do |t|
    t.string "name"
    t.date "date_from"
    t.date "date_to"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "project_id"
    t.binary "xlsx_file", size: :medium
    t.index ["project_id"], name: "index_survey_reports_on_project_id"
  end

  create_table "test_transactions", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.integer "amount_change", null: false
    t.integer "project_id", null: false
    t.integer "sample_id"
    t.integer "contractor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reserved_sample_code_id"
    t.index ["contractor_id"], name: "index_test_transactions_on_contractor_id"
    t.index ["project_id"], name: "index_test_transactions_on_project_id"
    t.index ["sample_id"], name: "index_test_transactions_on_sample_id"
  end

  create_table "tests", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.string "name"
    t.string "acronym"
    t.string "name_in_invoice"
    t.integer "project_id"
    t.integer "default_price_cents", default: 0, null: false
    t.string "default_price_currency", default: "PLN", null: false
    t.integer "material_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cito_default_price_cents", default: 0, null: false
    t.integer "cito_turnaround_hours"
    t.index ["project_id"], name: "fk_rails_2ed91c6953"
  end

  create_table "tests_prices", charset: "utf8", collation: "utf8_polish_ci", force: :cascade do |t|
    t.bigint "test_id", null: false
    t.integer "institution_id", null: false
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "PLN", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cito_price_cents"
    t.integer "cito_turnaround_hours"
    t.index ["institution_id"], name: "fk_rails_f9edb21757"
    t.index ["test_id"], name: "fk_rails_82784d5d9d"
  end

  add_foreign_key "AnalyteRanges", "Analytes", column: "AnalyteId", primary_key: "Id", name: "FK_AnalyteRanges_Analytes_AnalyteId"
  add_foreign_key "AnalyteResults", "Analytes", column: "AnalyteId", primary_key: "Id", name: "FK_AnalyteResults_Analytes_AnalyteId", on_update: :cascade, on_delete: :cascade
  add_foreign_key "AnalyteResults", "Results", column: "Result_MeasurementId", primary_key: "MeasurementId", name: "FK_AnalyteResults_Results_Result_MeasurementId"
  add_foreign_key "Analytes", "Projects", column: "ProjectId", primary_key: "Id", name: "FK_Analytes_Projects_ProjectId", on_update: :cascade, on_delete: :cascade
  add_foreign_key "CeraSamples", "Patients", column: "PatientId", primary_key: "Id", name: "FK_CeraSamples_Patients_PatientId"
  add_foreign_key "CeraSamples", "Samples", column: "SampleId", primary_key: "Id", name: "FK_CeraSamples_Samples_SampleId"
  add_foreign_key "Contractors", "agents"
  add_foreign_key "Contractors", "institutions"
  add_foreign_key "FileDatas", "Protocols", column: "ProtocolId", primary_key: "Id", name: "FK_FileDatas_Protocols_ProtocolId", on_update: :cascade, on_delete: :cascade
  add_foreign_key "GaSamples", "Patients", column: "PatientId", primary_key: "Id", name: "FK_GaSamples_Patients_PatientId"
  add_foreign_key "GaSamples", "Samples", column: "SampleId", primary_key: "Id", name: "FK_GaSamples_Samples_SampleId"
  add_foreign_key "LogMessages", "Users", column: "UserId", primary_key: "Id", name: "FK_LogMessages_Users_UserId"
  add_foreign_key "Measurements", "Projects", column: "ProjectId", primary_key: "Id"
  add_foreign_key "Measurements", "Projects", column: "ProjectId", primary_key: "Id", name: "FK_Measurements_Projects_ProjectId", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Measurements", "Samples", column: "SampleId", primary_key: "Id"
  add_foreign_key "Measurements", "Samples", column: "SampleId", primary_key: "Id", name: "FK_Measurements_Samples_SampleId", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Measurements", "Users", column: "AuthorizedById", primary_key: "Id", name: "FK_Measurements_Users_AuthorizedById"
  add_foreign_key "Measurements", "Users", column: "CreatedById", primary_key: "Id", name: "FK_Measurements_Users_CreatedById", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Measurements", "Users", column: "ModifiedById", primary_key: "Id", name: "FK_Measurements_Users_ModifiedById"
  add_foreign_key "Measurements", "instruments", column: "InstrumentId", name: "FK_Measurements_instruments_InstrumentId"
  add_foreign_key "Patients", "Contractors", column: "ContractorId", primary_key: "Id"
  add_foreign_key "Patients", "Contractors", column: "ContractorId", primary_key: "Id", name: "FK_Patients_Contractors_ContractorId", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Patients", "Users", column: "CreatedById", primary_key: "Id", name: "FK_Patients_Users_CreatedById"
  add_foreign_key "Patients", "Users", column: "ModifiedById", primary_key: "Id", name: "FK_Patients_Users_ModifiedById"
  add_foreign_key "PlateMeasurements", "Measurements", column: "MeasurementId", primary_key: "Id", name: "FK_PlateMeasurements_Measurements_MeasurementId"
  add_foreign_key "PlateMeasurements", "Plates", column: "PlateId", primary_key: "Id", name: "FK_PlateMeasurements_Plates_PlateId", on_update: :cascade, on_delete: :cascade
  add_foreign_key "PlateMeasurements", "Users", column: "CreatedById", primary_key: "Id", name: "FK_PlateMeasurements_Users_CreatedById", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Plates", "Multiplexes", column: "MultiplexId", primary_key: "Id", name: "FK_Plates_Multiplexes_MultiplexId"
  add_foreign_key "Plates", "Users", column: "CreatedById", primary_key: "Id", name: "FK_Plates_Users_CreatedById", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Plates", "Users", column: "ModifiedById", primary_key: "Id", name: "FK_Plates_Users_ModifiedById"
  add_foreign_key "ProtocolSamples", "Protocols", column: "Protocol_Id", primary_key: "Id", name: "FK_ProtocolSamples_Protocols_Protocol_Id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ProtocolSamples", "Samples", column: "Sample_Id", primary_key: "Id", name: "FK_ProtocolSamples_Samples_Sample_Id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Protocols", "Projects", column: "ProjectId", primary_key: "Id", name: "FK_Protocols_Projects_ProjectId"
  add_foreign_key "Protocols", "Users", column: "CreatedById", primary_key: "Id", name: "FK_Protocols_Users_CreatedById", on_update: :cascade, on_delete: :cascade
  add_foreign_key "ReservedSampleCodes", "Users", column: "CreatedById", primary_key: "Id", name: "FK_ReservedSampleCodes_Users_CreatedById"
  add_foreign_key "ReservedSampleCodes", "institutions", column: "InstitutionId", name: "FK_ReservedSampleCodes_institutions_InstitutionId"
  add_foreign_key "ReservedSampleCodes", "packages"
  add_foreign_key "Results", "Measurements", column: "MeasurementId", primary_key: "Id", name: "FK_Results_Measurements_MeasurementId"
  add_foreign_key "Results", "Users", column: "ImportUserId", primary_key: "Id", name: "FK_Results_Users_ImportUserId", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Samples", "Patients", column: "PatientId", primary_key: "Id"
  add_foreign_key "Samples", "Patients", column: "PatientId", primary_key: "Id", name: "FK_Samples_Patients_PatientId"
  add_foreign_key "Samples", "ReservedSampleCodes", column: "reserved_sample_code_id", primary_key: "Id", name: "fk_samples_reserved_sample_codes"
  add_foreign_key "Samples", "Users", column: "CancelledById", primary_key: "Id", name: "FK_Samples_Users_CancelledById"
  add_foreign_key "Samples", "Users", column: "UserId", primary_key: "Id", name: "FK_Samples_Users_UserId", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Samples", "soaking_degrees", name: "FK_Samples_soaking_degrees_soaking_degree_id"
  add_foreign_key "SamplesToCsvQueues", "Protocols", column: "ProtocolId", primary_key: "Id", name: "FK_SamplesToCsvQueues_Protocols_ProtocolId"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "answers", "Samples", primary_key: "Id"
  add_foreign_key "answers", "options"
  add_foreign_key "answers", "survey_questions"
  add_foreign_key "api_accounts", "Contractors", column: "contractor_id", primary_key: "Id"
  add_foreign_key "db_files", "fileables", name: "FK_db_files_fileables_fileable_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "hl7_imports", "Measurements", column: "measurement_id", primary_key: "Id"
  add_foreign_key "institutions", "agents", column: "created_by_agent_id"
  add_foreign_key "invoice_components", "Contractors", column: "contractor_id", primary_key: "Id"
  add_foreign_key "invoice_components", "institutions"
  add_foreign_key "invoice_components", "invoices"
  add_foreign_key "invoice_components", "tests"
  add_foreign_key "invoices", "institutions"
  add_foreign_key "kits", "ReservedSampleCodes", column: "reserved_sample_code_id", primary_key: "Id"
  add_foreign_key "kits", "Samples", column: "sample_id", primary_key: "Id"
  add_foreign_key "kits", "shop_orders"
  add_foreign_key "measurement_summaries", "institutions"
  add_foreign_key "measurement_summary_items", "Measurements", column: "measurement_id", primary_key: "Id"
  add_foreign_key "measurement_summary_items", "Projects", column: "project_id", primary_key: "Id"
  add_foreign_key "measurement_summary_items", "Samples", column: "sample_id", primary_key: "Id"
  add_foreign_key "measurement_summary_items", "measurement_summaries"
  add_foreign_key "measurement_summary_items", "tests"
  add_foreign_key "online_files", "Measurements", column: "measurement_id", primary_key: "Id", name: "FK_online_files_Measurements_measurement_id"
  add_foreign_key "packages", "production_orders"
  add_foreign_key "packages", "products"
  add_foreign_key "packages", "shop_orders"
  add_foreign_key "packages", "stock_rooms"
  add_foreign_key "production_orders", "products"
  add_foreign_key "production_orders", "stock_rooms"
  add_foreign_key "quality_control_components", "Analytes", column: "analyte_id", primary_key: "Id"
  add_foreign_key "quality_control_components", "quality_controls"
  add_foreign_key "quality_controls", "Projects", column: "project_id", primary_key: "Id"
  add_foreign_key "quality_controls", "Samples", column: "sample_id", primary_key: "Id"
  add_foreign_key "result_sending_events", "Measurements", column: "measurement_id", primary_key: "Id", name: "FK_result_sending_events_Measurements_measurement_id"
  add_foreign_key "result_sending_events", "Samples", column: "sample_id", primary_key: "Id", name: "FK_result_sending_events_Samples_sample_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "result_sending_events", "fileables", column: "id", name: "FK_result_sending_events_fileables_id"
  add_foreign_key "scanned_docs", "Samples", column: "sample_id", primary_key: "Id"
  add_foreign_key "sessions", "Contractors", column: "contractor_id", primary_key: "Id"
  add_foreign_key "shopify_order_deliveries", "shop_orders"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "survey_questions", "Projects", primary_key: "Id"
  add_foreign_key "survey_reports", "Projects", column: "project_id", primary_key: "Id"
  add_foreign_key "tests", "Projects", column: "project_id", primary_key: "Id"
  add_foreign_key "tests_prices", "institutions"
  add_foreign_key "tests_prices", "tests"
end
