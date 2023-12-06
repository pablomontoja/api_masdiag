class PatientPortal::SamplesController < ApplicationController
	include MasdiagCheck

	# required params: pesel and email
	def index		
		if params[:pesel].blank? || params[:email].blank?
			render(json: { message: "Lack of patient PESEL or email."}, status: 500)
			return
		end

		sample_ids = []
		sample_ids << meas_from_patients_table
		sample_ids << meas_from_shop_orders_table

 		samples = Sample.where(Id: sample_ids.flatten.uniq)
 		res = samples.map {|m| PatientPortal::Sample.new(m.Id).as_json.except("sample") }

 		render json: Oj.dump(res), status: 200
	end


private

	def meas_from_patients_table
		Measurement.includes(sample: :patient).where(Status: [1, 2, 3, 4, 7]).where(sample: {Patients: {Pesel: params[:pesel], email: params[:email]}}).pluck(:SampleId)
	end

  def meas_from_shop_orders_table
  	pack_ids = ShopOrder.where(email: params[:email]).map(&:package_ids).flatten
  	codes = ReservedSampleCode.where(package_id: pack_ids).pluck(:Code)
  	Measurement.includes(sample: :patient).where(Status: [1, 2, 3, 4, 7]).where(sample: {Code: codes}).where(sample: {Patients: {Pesel: params[:pesel]}}).pluck(:SampleId)
  end
	
end