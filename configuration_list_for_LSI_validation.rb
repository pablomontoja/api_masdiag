require 'bundler'
require 'csv'

# run with the following command:
# rails runner configuration_list_for_LSI_validation.rb
#
gems = Bundler::Definition.build('Gemfile', 'Gemfile.lock', nil).dependencies

# Prepare CSV file
CSV.open("tmp/LSI_validation_#{Time.now().strftime("%y%m%d-%H%M")}.csv", "wb") do |csv|
  # Add headers
  csv << ["Name", "Version", "URL"]

  # Iterate through each gem and fetch details
  gems.each do |gem|
    name = gem.name
    puts name
    gem_spec = Gem::Specification.find_all_by_name(name).first rescue nil
    next if gem_spec.nil?

    version = gem_spec&.version
    source_code_url = gem_spec&.metadata["source_code_uri"]
    source_code_url = gem_spec&.homepage if source_code_url.blank?
    source_code_url = "https://rubygems.org/gems/#{name}" if source_code_url.blank?  

    # Write to CSV
    csv << [name, version, source_code_url]
  end
end

puts "Gems list exported"