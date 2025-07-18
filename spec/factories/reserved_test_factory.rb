# == Schema Information
#
# Table name: reserved_tests
#
#  id                      :bigint           not null, primary key
#  project_id              :integer
#  reserved_sample_code_id :integer
#
FactoryBot.define do
  factory :reserved_test, class: ReservedTest do
    project
    reserved_sample_code
  end
end
