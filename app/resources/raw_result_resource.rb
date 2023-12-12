class RawResultResource < ApplicationService
	OneAnalyteRes = Struct.new(:parameter, :value, :unit)

  def initialize(meas)
    @meas = Measurement.includes(result: {analyte_results: :analyte}).includes(:sample).find(meas.Id)
    @product = @meas.sample.rsc&.package&.product
    @analyte_ids = Analyte.where(ProjectId: @meas.ProjectId).pluck(:Id)
    @hash = prepare_json
  end

  def call
    @hash
  end

  def prepare_json
    result = []

    return {raw_result: result} if @meas.nil? || @meas&.result.nil?

    @meas.result&.analyte_results&.each do |anres|
    	next if !(allowed_analyte_ids(@meas).include?(anres.AnalyteId))
    	result << OneAnalyteRes.new(anres.analyte.NameInAPI, prepare_value(anres), anres.Unit)
    end

    result
  end


  private

  def allowed_analyte_ids(meas)
  	case 
  	when @product&.id == 16
  		return [84]
  	when @product&.id == 17
  		return [84, 310]
  	else
  		return @analyte_ids
  	end
  end

  def prepare_value(anres)
    cutoff_down = anres.analyte.CutoffMin
    cutoff_up = anres.analyte.CutoffMax

    return round_value(anres) if cutoff_down.nil? || cutoff_up.nil?

    case
    when anres.Value < cutoff_down
      return "<#{BigDecimal(cutoff_down).to_f.round(2).to_s}"
    when anres.Value > cutoff_up
      return ">#{BigDecimal(cutoff_up).to_f.signif(3).to_s}"
    else
      return round_value(anres)
    end
  end


  def round_value(anres)
  	case 
  	when anres.Value < 1 || anres.Unit == "%"
  		return BigDecimal(anres.Value).to_f.round(2).to_s
  	else
  		return BigDecimal(anres.Value).to_f.signif(3).to_s
  	end
  	
  end


end
