module MasdiagMailer
	class SendCancellationNotificationsJob < ApplicationJob
	  require 'json'
	  # include Sidekiq::Worker

	  queue_as :default

	  def perform(sample_ids)
	    begin
	      sample_ids.each do |sample_id|

	        @sample = Sample.find(sample_id)
	        next if @sample == nil
	        next if @sample&.patient&.contractor&.api_account

	        # pudełko pochodzące z LEKAMu
	        rsc_box = ReservedSampleCode.includes(package: :product).where(package: {products: {type: [1, 4]}}).where(IsRetailSale: true).find_by(Code: @sample.Code)
	        if rsc_box != nil && rsc_box&.InstitutionId == 32
	          patient_email = @sample.patient.email if !@sample.patient&.email&.blank?
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient_standard_dbs_paper(sample_id).deliver_later if patient_email != nil
	          next
	        end

	        # pudełko pochodzące z AQIPHARM
	        if rsc_box != nil && rsc_box&.InstitutionId == 34
	          patient_email = @sample.patient.email if !@sample.patient&.email&.blank?
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_dziopa(sample_id).deliver_later
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient_standard_dbs_paper(sample_id).deliver_later if patient_email != nil
	          next
	        end

	        # pudełko od zarejestrowanej próbki
	        if !@sample.patient.IsVirtual && rsc_box != nil && rsc_box.parent_id == nil
	          patient_email = @sample.patient.email if !@sample.patient.email.blank?
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient(sample_id).deliver_later if patient_email != nil
	          next
	        end

	        # pudełko zapasowe
	        if !@sample.patient.IsVirtual && rsc_box != nil && rsc_box.parent_id != nil
	          patient_email = @sample.patient.email if !@sample.patient.email.blank?
	          # MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient(sample_id).deliver_later if patient_email != nil
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient_standard_dbs_paper(sample_id).deliver_later if patient_email != nil
	          next
	        end

	        # pudełko IsRetailSale:false od próbki zarejestrowanej poprzez partnerzy.masdiag.pl
	        rsc_box_without_retail_sale = ReservedSampleCode.includes(package: :product).where(package: {products: {type: [1, 4]}}).where(IsRetailSale: false).find_by(Code: @sample.Code)
	        if !@sample.patient.IsVirtual && rsc_box_without_retail_sale != nil && rsc_box_without_retail_sale.parent_id == nil && @sample.test_transaction.present?
	          patient_email = @sample.patient.email if !@sample.patient.email.blank?
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient(sample_id).deliver_later if patient_email != nil
	          next
	        end

	        #pudełko DIAGNOSTYKI PRECYZYJNEJ
	        if !@sample.patient.IsVirtual && !@sample.rsc&.shop_order.nil?
	          patient_email = @sample.patient.email if !@sample.patient.email.blank?
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient(sample_id).deliver_later if patient_email != nil
	          next
	        end


	        # anulowane kody paskowe
	        if /\A\d+\Z/.match?(@sample.Code) && (5000..15373).include?(Integer(@sample.Code))
	          if !@sample.patient.IsVirtual
	            contractor = Contractor.find(@sample.patient.ContractorId)
	            MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_contractor(sample_id, contractor.email).deliver_later if !contractor&.email.blank?
	            next
	          end
	        end

	        # anulowany LEKAM, pierwsze zamówienie
	        if /\A\d+\Z/.match?(@sample.Code) && (20000..22059).include?(Integer(@sample.Code))
	          if !@sample.patient.IsVirtual
	            contractor = Contractor.find(@sample.patient.ContractorId)
	            MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_contractor(sample_id, contractor.email).deliver_later if !contractor&.email.blank?
	            next
	          end
	        end

	        # do lekarzy, bibuła nie z pudełka
	        not_rsc_box = ReservedSampleCode.includes(package: :product).where.not(package: {products: {type: [1, 4]}}).find_by(Code: @sample.Code)
	        if !@sample.patient.IsVirtual && not_rsc_box != nil
	          contractor = Contractor.find(@sample.patient.ContractorId)
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_contractor(sample_id, contractor.email).deliver_later if !contractor&.email.blank?
	        end

	        # do pacjenta, bibuła nie z pudełka
	        if !@sample.patient.IsVirtual && not_rsc_box != nil
	          patient_email = @sample.patient.email if !@sample.patient.email.blank?

	          # TODO institutions excluded from SendCancellationNotificationsMailer#send_mail_to_patient_standard_dbs_paper should be at configuration or database level (flag as column in DB)
	          if @sample.patient.contractor.institution_id != 87 # HolisticaMed Aleksandra Ściebur
	            SendCancellationNotificationsMailer.send_mail_to_patient_standard_dbs_paper(sample_id).deliver_later if patient_email != nil && patient_email != "null"
	          end          
	        end

	      end

	    rescue StandardError => err
	      MasdiagMailer::SendErrorNotificationsMailer.send_mail({SendCancellationNotificationsJob: "ERROR: #{err}", SampleCode: @sample.Code})
	    end
	  end


	end
end



# # SendCancellationNotificationsJob - Use Cases

# ## Overview
# This job sends cancellation notifications for medical samples based on sample type, institution, and registration method.

# ---

# ## Exclusion Rules (Processed First)

# Samples are **skipped** if:
# - ❌ Sample not found
# - ❌ Contractor has API account (handles own notifications)
# - ❌ Institution is in `LALEN_INSTITUTION_IDS` list

# ---

# ## Use Case 1: LEKAM Institution Box
# **Institution ID:** 32

# ### Conditions
# - ✅ Retail sale box (`IsRetailSale: true`)
# - ✅ Product type: 1 or 4 (box products)
# - ✅ Institution ID is 32 (LEKAM)

# ### Actions
# | Recipient | Email Type |
# |-----------|------------|
# | Patient | `send_mail_to_patient_standard_dbs_paper` |

# ---

# ## Use Case 2: AQIPHARM Institution Box
# **Institution ID:** 34

# ### Conditions
# - ✅ Retail sale box (`IsRetailSale: true`)
# - ✅ Product type: 1 or 4
# - ✅ Institution ID is 34 (AQIPHARM)

# ### Actions
# | Recipient | Email Type |
# |-----------|------------|
# | Dziopa (Internal) | `send_mail_to_dziopa` |
# | Patient | `send_mail_to_patient_standard_dbs_paper` |

# ---

# ## Use Case 3: Primary Box - Registered Sample
# **Standard retail sale box**

# ### Conditions
# - ✅ Patient is NOT virtual
# - ✅ Box from retail sale (`IsRetailSale: true`)
# - ✅ Primary box (`parent_id == nil`)

# ### Actions
# | Recipient | Email Type |
# |-----------|------------|
# | Patient | `send_mail_to_patient` |

# ---

# ## Use Case 4: Spare/Backup Box
# **Secondary box from the same order**

# ### Conditions
# - ✅ Patient is NOT virtual
# - ✅ Box from retail sale
# - ✅ Spare box (`parent_id != nil`)

# ### Actions
# | Recipient | Email Type |
# |-----------|------------|
# | Patient | `send_mail_to_patient_standard_dbs_paper` |

# **Note:** Standard patient email is disabled for spare boxes.

# ---

# ## Use Case 5: Partner Portal Registration
# **Registration via partnerzy.masdiag.pl**

# ### Conditions
# - ✅ Patient is NOT virtual
# - ✅ Non-retail sale box (`IsRetailSale: false`)
# - ✅ Primary box (`parent_id == nil`)
# - ✅ Has test transaction

# ### Actions
# | Recipient | Email Type |
# |-----------|------------|
# | Patient | `send_mail_to_patient` |

# ---

# ## Use Case 6: Precision Diagnostics
# **Shop order samples**

# ### Conditions
# - ✅ Patient is NOT virtual
# - ✅ Sample has associated `shop_order`

# ### Actions
# | Recipient | Email Type |
# |-----------|------------|
# | Patient | `send_mail_to_patient` |

# ---

# ## Use Case 7: Cancelled Barcode Range (5000-15373)
# **Historical cancelled barcodes**

# ### Conditions
# - ✅ Patient is NOT virtual
# - ✅ Sample code is numeric
# - ✅ Code in range: **5000 to 15373**

# ### Actions
# | Recipient | Email Type |
# |-----------|------------|
# | Contractor | `send_mail_to_contractor` |

# ---

# ## Use Case 8: LEKAM First Order Range (20000-22059)
# **LEKAM initial order barcodes**

# ### Conditions
# - ✅ Patient is NOT virtual
# - ✅ Sample code is numeric
# - ✅ Code in range: **20000 to 22059**

# ### Actions
# | Recipient | Email Type |
# |-----------|------------|
# | Contractor | `send_mail_to_contractor` |

# ---

# ## Use Case 9: Non-Box DBS Paper - To Doctor
# **Individual DBS paper sheets**

# ### Conditions
# - ✅ Patient is NOT virtual
# - ✅ Product type is NOT 1 or 4 (not a box)
# - ✅ Reserved sample code exists

# ### Actions
# | Recipient | Email Type |
# |-----------|------------|
# | Contractor | `send_mail_to_contractor` |

# ---

# ## Use Case 10: Non-Box DBS Paper - To Patient
# **Individual DBS paper sheets**

# ### Conditions
# - ✅ Patient is NOT virtual
# - ✅ Product type is NOT 1 or 4 (not a box)
# - ✅ Reserved sample code exists
# - ❌ **Excluded:** HolisticaMed (Institution ID: 87)
# - ✅ Valid patient email (not blank, not \"null\")

# ### Actions
# | Recipient | Email Type |
# |-----------|------------|
# | Patient | `send_mail_to_patient_standard_dbs_paper` |

# ---

# ## Email Types Summary

# | Email Method | Description | Used In Cases |
# |--------------|-------------|---------------|
# | `send_mail_to_patient` | Standard patient cancellation | 3, 5, 6 |
# | `send_mail_to_patient_standard_dbs_paper` | Patient notification for DBS paper | 1, 2, 4, 10 |
# | `send_mail_to_contractor` | Contractor/doctor notification | 7, 8, 9 |
# | `send_mail_to_dziopa` | Internal stakeholder notification | 2 |

# ---

# ## Decision Flow Chart

# ```
# Sample Received
#     │
#     ├─> Excluded? (API account, LALEN) ──> SKIP
#     │
#     ├─> LEKAM Box (ID: 32)? ──> Email to Patient (DBS Paper)
#     │
#     ├─> AQIPHARM Box (ID: 34)? ──> Email to Dziopa + Patient (DBS Paper)
#     │
#     ├─> Primary Box + Virtual=false? ──> Email to Patient (Standard)
#     │
#     ├─> Spare Box + Virtual=false? ──> Email to Patient (DBS Paper)
#     │
#     ├─> Partner Portal (non-retail)? ──> Email to Patient (Standard)
#     │
#     ├─> Shop Order? ──> Email to Patient (Standard)
#     │
#     ├─> Barcode 5000-15373? ──> Email to Contractor
#     │
#     ├─> Barcode 20000-22059? ──> Email to Contractor
#     │
#     └─> Non-Box DBS Paper? ──> Email to Contractor + Patient (DBS Paper)
#                                 (Except HolisticaMed ID: 87)
#                                 ```

# ---

# ## Special Institution Rules

# | Institution | ID | Rule |
# |-------------|----|----|
# | LEKAM | 32 | Special patient DBS paper notification |
# | AQIPHARM | 34 | Notify Dziopa + Patient |
# | HolisticaMed | 87 | **Excluded** from patient DBS paper notifications |
# | LALEN | (constant) | **Skipped** entirely |

# ---

# ## Patient Type Rules

# | Patient Type | Virtual (`IsVirtual: true`) | Non-Virtual (`IsVirtual: false`) |
# |--------------|---------------------------|--------------------------------|
# | **Notifications Sent** | Only special cases (LEKAM, AQIPHARM) | Full notification rules apply |
# | **Use Cases Applied** | 1, 2 | 3, 4, 5, 6, 7, 8, 9, 10 |

# ---

# ## Product Types

# | Product Type | Description | Box Type |
# |--------------|-------------|----------|
# | 1, 4 | Box products | ✅ Box |
# | Other | Individual DBS papers | ❌ Not a box |

# ---

# ## Quick Reference: When is Each Email Sent?

# ### Patient Standard Email
# - Primary boxes (retail)
# - Partner portal registrations
# - Shop orders (Precision Diagnostics)

# ### Patient DBS Paper Email
# - LEKAM boxes
# - AQIPHARM boxes
# - Spare boxes
# - Non-box DBS papers (except HolisticaMed)

# ### Contractor Email
# - Cancelled barcode ranges (5000-15373, 20000-22059)
# - Non-box DBS papers to doctors

# ### Dziopa Email
# - AQIPHARM boxes only

# ---

# ## Validation Requirements

# Before sending any email, the job validates:
# - ✅ Patient email exists
# - ✅ Patient email is not blank
# - ✅ Patient email is not string `\"null\"`
# - ✅ Contractor email exists (for contractor notifications)
# - ✅ Contractor email is not blank

# ---

# ## Processing Order

# **Important:** Cases are evaluated in sequence. First match wins and processing stops (`next` statement).

# 1. LEKAM Box (32)
# 2. AQIPHARM Box (34)
# 3. Primary Box
# 4. Spare Box
# 5. Partner Portal
# 6. Precision Diagnostics
# 7. Barcode Range 1
# 8. Barcode Range 2
# 9. Non-Box to Contractor
# 10. Non-Box to Patient

# ---

# ## Error Handling

# All errors are caught and reported via:
# ```ruby
# SendErrorNotificationsMailer.send_mail({
#   SendCancellationNotificationsJob: \"ERROR: [message]\",
#   SampleCode: [sample_code]
#   })
# ```

# ---

# ## Usage

# ```ruby
# # Single sample
# SendCancellationNotificationsJob.perform_later([sample_id])

# # Multiple samples
# SendCancellationNotificationsJob.perform_later([id1, id2, id3])
# ```





# TODO SendCancellationNotificationsJob refactoring proposal

# Simplified Refactoring Proposal

# You're absolutely right. Let me propose a much simpler approach with just **4-5 new files** that addresses the core issues without over-engineering.

# ## Overview

# ### Core Problems to Solve
# 1. ❌ N+1 query problem (loading samples in loop)
# 2. ❌ Multiple similar queries repeated
# 3. ❌ 150+ lines in one method
# 4. ❌ Difficult to test
# 5. ❌ Magic numbers hardcoded

# ### Simple Solution
# - **1 Service Object** - handles all the decision logic
# - **1 Query Object** - consolidates RSC queries
# - **1 Config File** - centralizes magic numbers
# - **Refactored Job** - just coordinates
# - **Optional: 1 Helper** - for email validation

# **Total: 4-5 files instead of 20+**

# ---

# ## File Structure

# ```
# app/
# ├── jobs/
# │   └── send_cancellation_notifications_job.rb          # Refactored
# ├── services/
# │   └── sample_cancellation_notifier.rb                 # NEW - Main logic
# ├── queries/
# │   └── sample_reserved_code_finder.rb                  # NEW - Query logic
# └── lib/
#     └── email_validator.rb                              # NEW - Simple helper

# config/
# └── initializers/
#     └── cancellation_config.rb                          # NEW - Configuration
#     ```

# ---

# ## Implementation

# ### 1. Configuration (Centralize Magic Numbers)

# ```ruby
# # config/initializers/cancellation_config.rb

# module CancellationConfig
#   EXCLUDED_INSTITUTION_IDS = LALEN_INSTITUTION_IDS
  
#   INSTITUTIONS = {
#     lekam: 32,
#     aqipharm: 34,
#     holistica_med: 87
#   }.freeze
  
#   BARCODE_RANGES = {
#     cancelled: (5000..15373),
#     lekam_first_order: (20000..22059)
#   }.freeze
  
#   BOX_PRODUCT_TYPES = [1, 4].freeze
  
#   def self.numeric_code?(code)
#     /\\A\\d+\\Z/.match?(code)
#   end
  
#   def self.in_cancelled_range?(code)
#     numeric_code?(code) && BARCODE_RANGES[:cancelled].include?(code.to_i)
#   end
  
#   def self.in_lekam_range?(code)
#     numeric_code?(code) && BARCODE_RANGES[:lekam_first_order].include?(code.to_i)
#   end
#   end
# ```

# ---

# ### 2. Email Validator (Simple Helper)

# ```ruby
# # app/lib/email_validator.rb

# module EmailValidator
#   VALID_EMAIL_REGEX = /\\A[\\w+\\-.]+@[a-z\\d\\-]+(\\.[a-z\\d\\-]+)*\\.[a-z]+\\z/i

#   def self.valid?(email)
#       return false if email.blank?
#       return false if email.to_s == \"null\"
#       email.to_s.match?(VALID_EMAIL_REGEX)
#     end
#     end
#   ```

#   ---

#   ### 3. Query Object (Consolidate RSC Queries)

# ```ruby
# # app/queries/sample_reserved_code_finder.rb

# class SampleReservedCodeFinder
#   attr_reader :code, :retail_box, :non_retail_box, :non_box

#   def initialize(sample_code)
#       @code = sample_code
#       load_all
#     end

#   def retail_box?
#       retail_box.present?
#     end

#   def non_retail_box?
#       non_retail_box.present?
#     end

#   def non_box?
#       non_box.present?
#     end

#   private

#   def load_all
#       # Load all variants in one go to avoid multiple queries
#       all_codes = ReservedSampleCode
#         .includes(package: :product)
#         .where(Code: @code)
#         .to_a

#     @retail_box = all_codes.find do |rsc|
#           rsc.IsRetailSale == true && 
#           box_product?(rsc)
#         end

#     @non_retail_box = all_codes.find do |rsc|
#           rsc.IsRetailSale == false && 
#           box_product?(rsc)
#         end

#     @non_box = all_codes.find do |rsc|
#           !box_product?(rsc)
#         end
#       end

#   def box_product?(rsc)
#       rsc.package&.product&.type.in?(CancellationConfig::BOX_PRODUCT_TYPES)
#     end
#     end
#   ```

#   ---

#   ### 4. Service Object (Main Logic)

# ```ruby
# # app/services/sample_cancellation_notifier.rb

# class SampleCancellationNotifier
#   attr_reader :sample, :patient, :contractor, :rsc_finder

#   def initialize(sample)
#       @sample = sample
#       @patient = sample.patient
#       @contractor = patient&.contractor
#       @rsc_finder = SampleReservedCodeFinder.new(sample.Code)
#     end

#   def notify
#       return if should_skip?

#     # Check conditions in priority order and send appropriate emails
#         # Returns early after finding a match
#         send_lekam_notification ||
#         send_aqipharm_notification ||
#         send_registered_box_notification ||
#         send_spare_box_notification ||
#         send_partner_portal_notification ||
#         send_precision_diagnostics_notification ||
#         send_cancelled_barcode_notification ||
#         send_non_box_notifications
#       end

#   private

#   # Skip conditions
#     def should_skip?
#       sample.nil? ||
#       contractor&.api_account.present? ||
#       excluded_institution?
#     end

#   def excluded_institution?
#       CancellationConfig::EXCLUDED_INSTITUTION_IDS.include?(contractor&.institution_id)
#     end

#   # Notification methods - return truthy if handled, falsy if not applicable
    
#     def send_lekam_notification
#       return false unless rsc_finder.retail_box? && rsc_finder.retail_box.InstitutionId == CancellationConfig::INSTITUTIONS[:lekam]
      
#       send_patient_standard_dbs_paper
#       true
#     end

#   def send_aqipharm_notification
#       return false unless rsc_finder.retail_box? && rsc_finder.retail_box.InstitutionId == CancellationConfig::INSTITUTIONS[:aqipharm]
      
#       send_mail_to_dziopa
#       send_patient_standard_dbs_paper
#       true
#     end

#   def send_registered_box_notification
#       return false unless real_patient? && rsc_finder.retail_box? && rsc_finder.retail_box.parent_id.nil?
      
#       send_patient_standard
#       true
#     end

#   def send_spare_box_notification
#       return false unless real_patient? && rsc_finder.retail_box? && rsc_finder.retail_box.parent_id.present?
      
#       send_patient_standard_dbs_paper
#       true
#     end

#   def send_partner_portal_notification
#       return false unless real_patient? && 
#                           rsc_finder.non_retail_box? && 
#                           rsc_finder.non_retail_box.parent_id.nil? &&
#                           sample.test_transaction.present?
      
#       send_patient_standard
#       true
#     end

#   def send_precision_diagnostics_notification
#       return false unless real_patient? && sample.rsc&.shop_order.present?
      
#       send_patient_standard
#       true
#     end

#   def send_cancelled_barcode_notification
#       return false unless real_patient? && 
#                           (CancellationConfig.in_cancelled_range?(sample.Code) ||
#                            CancellationConfig.in_lekam_range?(sample.Code))
      
#       send_contractor_notification
#       true
#     end

#   def send_non_box_notifications
#       return false unless real_patient? && rsc_finder.non_box?
      
#       send_contractor_notification
#       send_patient_standard_dbs_paper unless patient_excluded_institution?
#       true
#     end

#   # Email sending helpers
    
#     def send_patient_standard
#       return unless valid_patient_email?
#       SendCancellationNotificationsMailer.send_mail_to_patient(sample.id).deliver_later
#     end

#   def send_patient_standard_dbs_paper
#       return unless valid_patient_email?
#       SendCancellationNotificationsMailer.send_mail_to_patient_standard_dbs_paper(sample.id).deliver_later
#     end

#   def send_contractor_notification
#       return unless valid_contractor_email?
#       SendCancellationNotificationsMailer.send_mail_to_contractor(sample.id, contractor.email).deliver_later
#     end

#   def send_mail_to_dziopa
#       SendCancellationNotificationsMailer.send_mail_to_dziopa(sample.id).deliver_later
#     end

#   # Validation helpers
    
#     def valid_patient_email?
#       EmailValidator.valid?(patient&.email)
#     end

#   def valid_contractor_email?
#       EmailValidator.valid?(contractor&.email)
#     end

#   def real_patient?
#       !patient&.IsVirtual
#     end

#   def patient_excluded_institution?
#       contractor&.institution_id == CancellationConfig::INSTITUTIONS[:holistica_med]
#     end
#     end
#   ```

#   ---

#   ### 5. Refactored Job

# ```ruby
# # app/jobs/send_cancellation_notifications_job.rb

# class SendCancellationNotificationsJob < ApplicationJob
#   queue_as :default

#   def perform(sample_ids)
#       samples = load_samples_with_associations(sample_ids)
      
#       samples.each do |sample|
#         process_sample(sample)
#       end
#     rescue StandardError => e
#       handle_error(e, sample_ids)
#       raise
#     end

#   private

#   def load_samples_with_associations(sample_ids)
#       Sample
#         .where(id: sample_ids)
#         .includes(
#           :test_transaction,
#           :rsc,
#           patient: { contractor: :institution }
#         )
#     end

#   def process_sample(sample)
#       SampleCancellationNotifier.new(sample).notify
#     rescue StandardError => e
#       log_sample_error(sample, e)
#       SendErrorNotificationsMailer.send_mail(
#         SendCancellationNotificationsJob: \"ERROR: #{e}\",
#         SampleCode: sample.Code
#       ).deliver_now
#     end

#   def handle_error(error, sample_ids)
#       Rails.logger.error(
#         \"SendCancellationNotificationsJob failed\",
#         error: error.message,
#         sample_ids: sample_ids
#       )
#     end

#   def log_sample_error(sample, error)
#       Rails.logger.error(
#         \"Failed to send cancellation notification\",
#         sample_id: sample.id,
#         sample_code: sample.Code,
#         error: error.message
#       )
#     end
#     end
#   ```

#   ---

#   ## Testing Strategy

# ### Job Test

# ```ruby
# # spec/jobs/send_cancellation_notifications_job_spec.rb

# require 'rails_helper'

# RSpec.describe SendCancellationNotificationsJob do
#   describe '#perform' do
#     let!(:sample1) { create(:sample) }
#     let!(:sample2) { create(:sample) }
#     let(:sample_ids) { [sample1.id, sample2.id] }

#     it 'loads samples with associations' do
#           expect(Sample).to receive(:where).with(id: sample_ids).and_call_original
#           subject.perform(sample_ids)
#         end

#     it 'processes each sample' do
#           notifier1 = instance_double(SampleCancellationNotifier)
#           notifier2 = instance_double(SampleCancellationNotifier)
          
#           allow(SampleCancellationNotifier).to receive(:new).with(sample1).and_return(notifier1)
#           allow(SampleCancellationNotifier).to receive(:new).with(sample2).and_return(notifier2)
#           allow(notifier1).to receive(:notify)
#           allow(notifier2).to receive(:notify)

#       subject.perform(sample_ids)

#       expect(notifier1).to have_received(:notify)
#             expect(notifier2).to have_received(:notify)
#           end

#     context 'when sample processing fails' do
#           before do
#             allow_any_instance_of(SampleCancellationNotifier)
#               .to receive(:notify).and_raise(StandardError.new(\"Test error\"))
#             allow(SendErrorNotificationsMailer).to receive(:send_mail)
#               .and_return(double(deliver_now: true))
#           end

#       it 'sends error notification and continues' do
#               expect { subject.perform(sample_ids) }.to raise_error(StandardError)
#               expect(SendErrorNotificationsMailer).to have_received(:send_mail).at_least(:once)
#             end
#           end
#         end
#       end
#       ```

#       ---

#       ### Service Test

# ```ruby
# # spec/services/sample_cancellation_notifier_spec.rb

# require 'rails_helper'

# RSpec.describe SampleCancellationNotifier do
#   let(:sample) { create(:sample, Code: code) }
#   let(:code) { 'TEST001' }
  
#   subject { described_class.new(sample) }

#   describe '#notify' do
#       context 'when sample should be skipped' do
#         context 'with api account' do
#           before do
#             sample.patient.contractor.update(api_account: create(:api_account))
#           end

#         it 'does not send notifications' do
#                   expect(SendCancellationNotificationsMailer).not_to receive(:send_mail_to_patient)
#                   subject.notify
#                 end
#               end

#       context 'with excluded institution' do
#               before do
#                 stub_const('CancellationConfig::EXCLUDED_INSTITUTION_IDS', 
#                           [sample.patient.contractor.institution_id])
#               end

#         it 'does not send notifications' do
#                   expect(SendCancellationNotificationsMailer).not_to receive(:send_mail_to_patient)
#                   subject.notify
#                 end
#               end
#             end

#     context 'LEKAM institution' do
#           let!(:rsc) do
#             create(:reserved_sample_code,
#               Code: code,
#               InstitutionId: CancellationConfig::INSTITUTIONS[:lekam],
#               IsRetailSale: true,
#               package: create(:package, product: create(:product, type: 1))
#             )
#           end

#       before do
#               sample.patient.update(email: 'patient@example.com')
#             end

#       it 'sends standard DBS paper notification' do
#               expect(SendCancellationNotificationsMailer)
#                 .to receive(:send_mail_to_patient_standard_dbs_paper)
#                 .with(sample.id)
#                 .and_return(double(deliver_later: true))

#         subject.notify
#               end
#             end

#     context 'AQIPHARM institution' do
#           let!(:rsc) do
#             create(:reserved_sample_code,
#               Code: code,
#               InstitutionId: CancellationConfig::INSTITUTIONS[:aqipharm],
#               IsRetailSale: true,
#               package: create(:package, product: create(:product, type: 1))
#             )
#           end

#       before do
#               sample.patient.update(email: 'patient@example.com')
#             end

#       it 'sends notification to dziopa and patient' do
#               expect(SendCancellationNotificationsMailer)
#                 .to receive(:send_mail_to_dziopa)
#                 .with(sample.id)
#                 .and_return(double(deliver_later: true))

#         expect(SendCancellationNotificationsMailer)
#                   .to receive(:send_mail_to_patient_standard_dbs_paper)
#                   .with(sample.id)
#                   .and_return(double(deliver_later: true))

#         subject.notify
#               end
#             end

#     context 'registered sample box' do
#           let!(:rsc) do
#             create(:reserved_sample_code,
#               Code: code,
#               InstitutionId: 50,
#               IsRetailSale: true,
#               parent_id: nil,
#               package: create(:package, product: create(:product, type: 1))
#             )
#           end

#       before do
#               sample.patient.update(email: 'patient@example.com', IsVirtual: false)
#             end

#       it 'sends standard patient notification' do
#               expect(SendCancellationNotificationsMailer)
#                 .to receive(:send_mail_to_patient)
#                 .with(sample.id)
#                 .and_return(double(deliver_later: true))

#         subject.notify
#               end
#             end

#     context 'spare box' do
#           let!(:rsc) do
#             create(:reserved_sample_code,
#               Code: code,
#               InstitutionId: 50,
#               IsRetailSale: true,
#               parent_id: 123,
#               package: create(:package, product: create(:product, type: 1))
#             )
#           end

#       before do
#               sample.patient.update(email: 'patient@example.com', IsVirtual: false)
#             end

#       it 'sends standard DBS paper notification' do
#               expect(SendCancellationNotificationsMailer)
#                 .to receive(:send_mail_to_patient_standard_dbs_paper)
#                 .with(sample.id)
#                 .and_return(double(deliver_later: true))

#         subject.notify
#               end
#             end

#     context 'cancelled barcode range' do
#           let(:code) { '10000' }

#       before do
#               sample.patient.update(IsVirtual: false)
#               sample.patient.contractor.update(email: 'contractor@example.com')
#             end

#       it 'sends contractor notification' do
#               expect(SendCancellationNotificationsMailer)
#                 .to receive(:send_mail_to_contractor)
#                 .with(sample.id, 'contractor@example.com')
#                 .and_return(double(deliver_later: true))

#         subject.notify
#               end
#             end

#     context 'with invalid patient email' do
#           let!(:rsc) do
#             create(:reserved_sample_code,
#               Code: code,
#               InstitutionId: CancellationConfig::INSTITUTIONS[:lekam],
#               IsRetailSale: true,
#               package: create(:package, product: create(:product, type: 1))
#             )
#           end

#       before do
#               sample.patient.update(email: 'null')
#             end

#       it 'does not send patient notification' do
#               expect(SendCancellationNotificationsMailer)
#                 .not_to receive(:send_mail_to_patient_standard_dbs_paper)

#         subject.notify
#               end
#             end
#           end
#         end
#         ```

#         ---

#         ### Query Test

# ```ruby
# # spec/queries/sample_reserved_code_finder_spec.rb

# require 'rails_helper'

# RSpec.describe SampleReservedCodeFinder do
#   let(:code) { 'TEST001' }
  
#   subject { described_class.new(code) }

#   context 'with retail box' do
#       let!(:rsc) do
#         create(:reserved_sample_code,
#           Code: code,
#           IsRetailSale: true,
#           package: create(:package, product: create(:product, type: 1))
#         )
#       end

#     it 'finds retail box' do
#           expect(subject.retail_box).to eq(rsc)
#           expect(subject.retail_box?).to be true
#         end
#       end

#   context 'with non-retail box' do
#       let!(:rsc) do
#         create(:reserved_sample_code,
#           Code: code,
#           IsRetailSale: false,
#           package: create(:package, product: create(:product, type: 1))
#         )
#       end

#     it 'finds non-retail box' do
#           expect(subject.non_retail_box).to eq(rsc)
#           expect(subject.non_retail_box?).to be true
#         end
#       end

#   context 'with non-box product' do
#       let!(:rsc) do
#         create(:reserved_sample_code,
#           Code: code,
#           package: create(:package, product: create(:product, type: 5))
#         )
#       end

#     it 'finds non-box' do
#           expect(subject.non_box).to eq(rsc)
#           expect(subject.non_box?).to be true
#         end
#       end

#   context 'with multiple codes' do
#       let!(:retail_rsc) do
#         create(:reserved_sample_code,
#           Code: code,
#           IsRetailSale: true,
#           package: create(:package, product: create(:product, type: 1))
#         )
#       end

#     let!(:non_retail_rsc) do
#           create(:reserved_sample_code,
#             Code: code,
#             IsRetailSale: false,
#             package: create(:package, product: create(:product, type: 1))
#           )
#         end

#     it 'finds all variants' do
#           expect(subject.retail_box).to eq(retail_rsc)
#           expect(subject.non_retail_box).to eq(non_retail_rsc)
#         end
#       end
#     end
#     ```

#     ---

#     ## Migration Plan (Simplified)

# ### Week 1: Development & Testing
# ```bash
# # Day 1-2: Create new files
# touch config/initializers/cancellation_config.rb
# touch app/lib/email_validator.rb
# touch app/queries/sample_reserved_code_finder.rb
# touch app/services/sample_cancellation_notifier.rb

# # Day 3-4: Write tests
# # Day 5: Code review
# ```

# ### Week 2: Deployment
# ```bash
# # Day 1: Deploy to staging
# # Day 2-3: Test in staging
# # Day 4: Deploy to production (off-hours)
# # Day 5: Monitor
# ```

# ### Week 3: Validation & Cleanup
# ```bash
# # Monitor error rates, email delivery
# # If stable for 1 week, done!
# ```

# ---

# ## Comparison: Before vs After

# ### Before
# ```
# app/jobs/send_cancellation_notifications_job.rb (1 file, 150 lines)
#   └─> Everything in one method
# ```

# ### After
# ```
# app/jobs/send_cancellation_notifications_job.rb (45 lines)
#   └─> Delegates to service

# app/services/sample_cancellation_notifier.rb (120 lines)
#   └─> All business logic, clean & organized

# app/queries/sample_reserved_code_finder.rb (40 lines)
#   └─> Query logic

# app/lib/email_validator.rb (10 lines)
#   └─> Simple validation

# config/initializers/cancellation_config.rb (25 lines)
#   └─> Configuration
# ```

# **Total: 5 files, ~240 lines (well-organized) vs 1 file, 150 lines (spaghetti)**

# ---

# ## Key Benefits

# ✅ **Only 4-5 new files** (not 20+)
# ✅ **Fixes N+1 query problem** (eager loading)
# ✅ **Testable** (each class has focused responsibility)
# ✅ **Readable** (clear method names, logical flow)
# ✅ **Maintainable** (easy to find and modify logic)
# ✅ **Same functionality** (100% backward compatible)

# ---

# ## Quick Win Alternative (Even Simpler!)

# If you want **just 2 files**, here's an even more minimal approach:

# ### Option: Extract Only Query & Config

# ```ruby
# # config/initializers/cancellation_config.rb
# # (same as above)

# # app/queries/sample_reserved_code_finder.rb  
# # (same as above)

# # app/jobs/send_cancellation_notifications_job.rb
# class SendCancellationNotificationsJob < ApplicationJob
#   def perform(sample_ids)
#     samples = Sample.where(id: sample_ids)
#                    .includes(:test_transaction, :rsc, 
#                             patient: { contractor: :institution })
    
#     samples.each { |sample| process_sample(sample) }
#   end
  
#   private
  
#   def process_sample(sample)
#     return if should_skip?(sample)
    
#     rsc = SampleReservedCodeFinder.new(sample.Code)
    
#     send_lekam_notification(sample, rsc) ||
#     send_aqipharm_notification(sample, rsc) ||
#     # ... etc (extract current logic into private methods)
#   end
  
#   # Private methods for each case...
# end
# ```

# This gives you **80% of the benefit with just 2 new files**!

# What do you think? Would you prefer:
# 1. The 5-file approach (more organized)
# 2. The 2-file approach (minimal change)
# 3. Something in between?