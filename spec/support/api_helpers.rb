module ApiHelpers
  def json
    JSON.parse(response.body)
  end

  def http_login
    user = 'username'
    pw = 'password'
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
  end  

  def http_auth_header
    {"Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("username","password")}
  end

  def http_auth_header_with_json_content_type
    {"Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("username","password"), 'Content-Type' => 'application/json'}
  end

  def generate_results(codes: [])
    file = File.open("scripts/blank.pdf")
    Measurement.includes(:sample).where(sample: {Code: codes}).each do |meas|
      meas.online_file&.destroy
      of = OnlineFile.new(measurement_id: meas.Id, file_size: file.size, encrypted_file_size: file.size, filename: "#{meas.sample.Code}_#{meas.ProjectId}", content_type: "application/pdf")
      of.file_contents = file.read
      file.rewind
      of.encrypted_file_contents = file.read
      file.rewind
      of.save
      meas.update(Status: 5, MeasureDate: DateTime.now, AuthorizedAt: DateTime.now, CuttedAt: DateTime.now, InstrumentId: nil)
      meas.sample.update(AcceptanceDate: DateTime.now-2.days, soaking_degree_id: nil, SampleStatus: 2, SampleState: 2)
    end
  end
end
