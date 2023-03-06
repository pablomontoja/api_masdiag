class SampleResource
  include Alba::Resource

  root_key :sample
  attributes :id
  attribute :code, &:Code

  attribute :tests do |resource|
    resource.measurements.map { |m| m.project.Name }
  end

end
