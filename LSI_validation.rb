require 'bundler'
require 'csv'
require 'rspec/core'

# run with the following command:
#
# rails runner LSI_validation.rb
#
puts "-------------------------------------------------------------"
puts "GEMS list in preparation"

gems = Bundler::Definition.build('Gemfile', 'Gemfile.lock', nil).dependencies
time_signature = Time.now().strftime("%y%m%d-%H%M")
configuration_list_filename = "LSI_validation/#{time_signature}_configuration_list.csv"

# Prepare configuration list CSV file
CSV.open(configuration_list_filename, "wb") do |csv|
  # Add headers
  csv << ["Name", "Version", "URL"]

  # Iterate through each gem and fetch details
  gems.each do |gem|
    name = gem.name
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


puts "-------------------------------------------------------------"
puts "Gems list exported to #{configuration_list_filename}"
puts "-------------------------------------------------------------"
puts ""

other_info_filename = "LSI_validation/#{time_signature}_system_user_and_tools_info.txt"

puts "-------------------------------------------------------------"
puts "Get system, user and tools info"
puts "-------------------------------------------------------------"

File.open(other_info_filename, 'w') do |f|
  f.puts "-------------------------------------------------------------"
  f.puts "Get USER info"
  f.puts "-------------------------------------------------------------"
  f.puts "Username: " + `whoami`
  f.puts `id`
  f.puts ""
  f.puts "-------------------------------------------------------------"
  f.puts "Get OS info"
  f.puts "-------------------------------------------------------------"
  f.puts `lsb_release -a`
  f.puts `cat /proc/version`
  f.puts ""
  f.puts "-------------------------------------------------------------"
  f.puts "Get tools info"
  f.puts "-------------------------------------------------------------"
  f.puts `subl -v`
  f.puts "-----------------------"
  f.puts `git --version`
  f.puts "-----------------------"
  f.puts `rvm -v`
  f.puts "-----------------------"
  f.puts "Visual Studio Code"
  f.puts `code -v`
  f.puts ""
  f.puts "-------------------------------------------------------------"
  f.puts "Last 10 commits git logs"
  f.puts "-------------------------------------------------------------"
  f.puts `git --no-pager log --format=short -n 10`
  f.puts "-------------------------------------------------------------"
end

puts "-------------------------------------------------------------"
puts "System, user and tools info exported to #{other_info_filename}"
puts "-------------------------------------------------------------"
puts ""
puts ""
puts ""
puts "-------------------------------------------------------------"
puts "You must run RSPEC tests with rspec command."
puts "If you want create report during the tests change the .rspec file and tests results will be avaialable at ./LSI_validation/latest-rspec-tests.txt"
puts "-------------------------------------------------------------"
