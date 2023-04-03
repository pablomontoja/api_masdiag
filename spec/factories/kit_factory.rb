FactoryBot.define do
  factory :test_assignment, class: Hash do
    data do
      {
        "code": "JV4XJ",
        "test_ids": [2, 3]
      }
    end
    skip_create
    initialize_with { attributes }
  end
end

# FactoryBot.define do
#   factory :kit, class: Kit do
#   	shop_product_json { "[{\"mode\":\"builder\",\"cssclass\":\"witaminad\",\"hidelabelincart\":\"\",\"hidevalueincart\":\"\",\"hidelabelinorder\":\"\",\"hidevalueinorder\":\"\",\"element\":{\"type\":\"checkbox\",\"rules_type\":{\"Badanie poziomu Witaminy D_0\":[\"\"],\"Profil Aminokwasów_1\":[\"\"],\"Badanie stężenia THC _2\":[\"\"],\"Przeciwciała anty-SARS-CoV-2_3\":[\"\"],\"Pakiet odpornościowy - Wit. D i przeciwciała anty-SARS-CoV-2_4\":[\"\"]},\"_\":{\"price_type\":false}},\"name\":\"\",\"value\":\"Badanie poziomu Witaminy D\",\"price\":129.0,\"section\":\"5f11f1ebe3ac71.74728245\",\"section_label\":\"\",\"percentcurrenttotal\":0,\"fixedcurrenttotal\":0,\"currencies\":[],\"price_per_currency\":{\"PLN\":129.0},\"quantity\":1,\"multiple\":\"1\",\"key\":\"Badanie poziomu Witaminy D_0\",\"use_images\":\"\",\"use_colors\":\"\",\"changes_product_image\":\"\",\"imagesp\":\"\",\"images\":\"\",\"color\":\"\"}]" }
#     own_product_json { "[{\"project_id\":2,\"analyte_ids\":[null],\"shop_product_name\":\"Badanie poziomu Witaminy D\"}]" }
#   end
# end



# "id":"275"
# "shop_id":null
# "tag_content":null
# "sample_id":null
# "is_registered":null
# "shop_product_json":"[{\"mode\":\"builder\",\"cssclass\":\"witaminad\",\"hidelabelincart\":\"\",\"hidevalueincart\":\"\",\"hidelabelinorder\":\"\",\"hidevalueinorder\":\"\",\"element\":{\"type\":\"checkbox\",\"rules_type\":{\"Badanie poziomu Witaminy D_0\":[\"\"],\"Profil Aminokwasów_1\":[\"\"],\"Badanie stężenia THC _2\":[\"\"],\"Przeciwciała anty-SARS-CoV-2_3\":[\"\"],\"Pakiet odpornościowy - Wit. D i przeciwciała anty-SARS-CoV-2_4\":[\"\"]},\"_\":{\"price_type\":false}},\"name\":\"\",\"value\":\"Badanie poziomu Witaminy D\",\"price\":129.0,\"section\":\"5f11f1ebe3ac71.74728245\",\"section_label\":\"\",\"percentcurrenttotal\":0,\"fixedcurrenttotal\":0,\"currencies\":[],\"price_per_currency\":{\"PLN\":129.0},\"quantity\":1,\"multiple\":\"1\",\"key\":\"Badanie poziomu Witaminy D_0\",\"use_images\":\"\",\"use_colors\":\"\",\"changes_product_image\":\"\",\"imagesp\":\"\",\"images\":\"\",\"color\":\"\"}]"
# "own_product_json":"[{\"project_id\":2,\"analyte_ids\":[null],\"shop_product_name\":\"Badanie poziomu Witaminy D\"}]"
# "created_at":"2022-01-10 08:24:14"
# "updated_at":"2022-01-10 08:24:14"
# "shop_order_id":"517"
# "reserved_sample_code_id":"11953"
