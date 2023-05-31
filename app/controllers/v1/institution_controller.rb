class V1::InstitutionController < ApplicationController

  def pool_status
    avail_tests = InstitutionTest.where(institution_id: Current.api_account.institution.id, used: false).all
    avail_list = avail_tests.group_by{|it| it.project}.map { |k, v| {"#{k.eng_name}": v.size}  }.reduce(&:merge)

    used_tests = InstitutionTest.where(institution_id: Current.api_account.institution.id, used: true).all
    used_list = used_tests.group_by{|it| it.project}.map { |k, v| {"#{k.eng_name}": v.size}  }.reduce(&:merge)

    response_hash = {}
    response_hash[:available_tests] = avail_list
    response_hash[:used_tests] = used_list

    json_response(response_hash)
  end


end
