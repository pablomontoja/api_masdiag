# == Schema Information
#
# Table name: soaking_degrees
#
#  id   :integer          not null, primary key
#  name :text(4294967295)
#  sn   :integer          not null
#
FactoryBot.define do
  factory :soaking_degree do
    name { "dobrze" }
    sn { 1 }
  end
end
