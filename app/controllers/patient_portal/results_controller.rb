class PatientPortal::ResultsController < ApplicationController
	include MasdiagCheck

	# required params: pesel and email
	def index		
		if params[:pesel].blank? || params[:email].blank?
			render(json: { message: "Lack of patient PESEL or email."}, status: 500)
			return
		end

		meas_ids = []
		meas_ids << meas_from_patients_table
		meas_ids << meas_from_shop_orders_table

 		meases = Measurement.where(Id: meas_ids.flatten.uniq)
 		results = meases.map {|m| PatientPortal::Result.new(m.Id).as_json.except("measurement") }

 		render json: Oj.dump(results), status: 200		
	end


private

	def meas_from_patients_table
		Measurement.includes(sample: :patient).where(Status: 5).where(sample: {Patients: {Pesel: params[:pesel], email: params[:email]}}).pluck(:Id)
	end

  def meas_from_shop_orders_table
  	pack_ids = ShopOrder.where(email: params[:email]).map(&:package_ids).flatten
  	codes = ReservedSampleCode.where(package_id: pack_ids).pluck(:Code)
  	Measurement.includes(sample: :patient).where(Status: 5).where(sample: {Code: codes}).where(sample: {Patients: {Pesel: params[:pesel]}}).pluck(:Id)
  end
	
end