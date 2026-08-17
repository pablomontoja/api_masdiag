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
