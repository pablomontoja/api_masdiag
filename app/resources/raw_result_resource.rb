class RawResultResource < ApplicationService
	OneAnalyteRes = Struct.new(:parameter, :value, :unit)

  def initialize(meas)
    @meas = meas
    @hash = prepare_json
  end

  def call
  	pp @hash
    @hash
  end

  def prepare_json
    result = []

    return {json_result: result} if @meas.nil?

    @meas.result&.analyte_results.each do |anres|
    	next if !(allowed_analyte_ids(@meas).include?(anres.AnalyteId))
    	result << OneAnalyteRes.new(anres.analyte.NameInAPI, round_value(anres), anres.Unit)
    end

    result
  end


  private

  def allowed_analyte_ids(meas)
  	product = meas.sample.rsc&.package&.product

  	case 
  	when product.id == 16
  		return [84]
  	when product.id == 17
  		return [84, 310]
  	else
  		return Analyte.where(ProjectId: meas.ProjectId).pluck(:Id)
  	end
  end


  def round_value(anres)
  	case 
  	when anres.Value < 1 || anres.Unit == "%"
  		return BigDecimal(anres.Value).to_f.round(2)
  	else
  		return BigDecimal(anres.Value).to_f.signif(3)
  	end
  	
  end


end
