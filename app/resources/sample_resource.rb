class SampleResource
  include Alba::Resource

  root_key :sample
  attributes :id
  attribute :code, &:Code

  attribute :tests do |resource|
    proj_ids = resource.measurements.map { |m| m.ProjectId }
    tests = V1::Common::AVAILABLE_TESTS
    tests.select{|t| proj_ids.include?(t[:id]) }.map{|t| t[:name]}
  end

end
