# == Schema Information
#
# Table name: config_entries
#
#  id          :integer          not null, primary key
#  key         :string(255)      not null
#  json        :text(4294967295)
#  config_type :string(255)
#
class KeyValueDbStore < ApplicationRecord
  self.table_name = "config_entries"
  self.primary_key = "id"

  serialize :json, coder: ::ActiveRecord::Coders::JSON


  def self.metanephrine_settled_samples
    self.find_by(key: "MetanephrineSettledSamples")&.json || self.create(key: "MetanephrineSettledSamples", json: []).json
  end

  def self.metanephrine_settled_samples=(sample_codes)
    kv = self.find_by(key: "MetanephrineSettledSamples")
    kv.update(json: sample_codes)
  end
end
