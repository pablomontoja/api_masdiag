module ApiHelpers
  def json
    JSON.parse(response.body)
  end

  def sample_cancellation_json
    %Q(
      {
        "cancellation": {
          "sample_code": "JV4XJ",
          "cancellation_date": "2024-02-14T14:32:21.349+01:00",
          "cancellation_reason": "za niska karnityna",
          "cancelled_by_email": "pawel.swider@masdiag.pl",
          "should_backup_kit_be_sent": true
        }
      }
    )
  end

  def correct_import
    %Q(
						[
        {
          "order_number": "9800",
          "order_date": "2022-05-10 10:50",
          "billing_first_name": "Tomasz",
          "billing_last_name": "Bialik",
          "billing_email": "tbialik@onet.pl",
          "billing_phone": "+48790582587",
          "First Name (Shipping)": "Tomasz",
          "Last Name (Shipping)": "Bialik",
          "Address 1&amp;2 (Shipping)": "Zawiszy Czarnego 4\/50, Ci\u0105g dalszy adresu - adres 2",
          "Postcode (Shipping)": "40-872",
          "City (Shipping)": "Katowice",
          "products": [
            {
              "Product Name (main)": "Badanie st\u0119\u017cenia witaminy D",
              "Product Current Price": "450",
              "Quantity": "1",
              "_tmcartepo_data": ""
            }
          ],
          "coupons": [
            {
              "Coupon Code": "jps10",
              "Coupon Amount": "10",
              "Discount Amount": "45"
            }
          ]
        }
      ]
      	)
  end

  def incorrect_import
    %Q(
						[
        {
          "order_number": "9800",
          "order_date": "2022-05-10 10:50",
          "billing_first_name": "Tomasz",
          "billing_last_name": "Bialik",
          "billing_email": "",
          "billing_phone": "+48790582587",
          "First Name (Shipping)": "Tomasz",
          "Last Name (Shipping)": "Bialik",
          "Address 1&amp;2 (Shipping)": "Zawiszy Czarnego 4\/50, Ci\u0105g dalszy adresu - adres 2",
          "Postcode (Shipping)": "40-872",
          "City (Shipping)": "Katowice",
          "products": [
            {
              "Product Name (main)": "Badanie st\u0119\u017cenia witaminy D",
              "Quantity": "1",
              "_tmcartepo_data": ""
            }
          ]
        }
      ]
      	)
  end

  def two_kits_correct_import
    %Q(
						[
        {
          "order_number": "9800",
          "order_date": "2022-05-10 10:50",
          "billing_first_name": "Tomasz",
          "billing_last_name": "Bialik",
          "billing_email": "tbialik@onet.pl",
          "billing_phone": "+48790582587",
          "First Name (Shipping)": "Tomasz",
          "Last Name (Shipping)": "Bialik",
          "Address 1&amp;2 (Shipping)": "Zawiszy Czarnego 4\/50, Ci\u0105g dalszy adresu - adres 2",
          "Postcode (Shipping)": "40-872",
          "City (Shipping)": "Katowice",
          "products": [
            {
              "Product Name (main)": "Badanie st\u0119\u017cenia witaminy D",
              "Product Current Price": "450",
              "Quantity": "2",
              "_tmcartepo_data": ""
            }
          ],
          "coupons": [
            {
              "Coupon Code": "jps10",
              "Coupon Amount": "10",
              "Discount Amount": "45"
            }
          ]
        }
      ]
      	)
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
