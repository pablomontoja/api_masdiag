module Cerascreen
	module Labordatenbank
		class GetResultsJob < ApplicationJob
			retry_on StandardError, wait: :polynomially_longer, attempts: 5 do |job, error|
		    Sentry.capture_exception(error)
		  end

			def perform
				return if Rails.env.development?
				@meases = Measurement.includes(:sample).where(Status: [1, 2], ProjectId: 24)

				@meases.each do |m|
					resp = Cerascreen::Labordatenbank::GetResultSvc.call(m.sample.Code)
					next if resp.nil?
					Cerascreen::Labordatenbank::ResultImporterJob.perform_later(m.sample.Code)
				end
			end

		end
	end
end