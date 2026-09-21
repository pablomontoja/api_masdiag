namespace :labsample_releases do
  desc "Add a new LabsampleRelease with the given version, attaching a local .7z archive"
  task :add, [:version, :archive_path] => :environment do |_t, args|
    version = args[:version]
    archive_path = args[:archive_path]

    abort("Usage: rails labsample_releases:add[<version>,<path to .7z file>]") if version.blank? || archive_path.blank?
    abort("File not found: #{archive_path}") unless File.exist?(archive_path)
    abort("Expected a .7z file, got: #{archive_path}") unless File.extname(archive_path).casecmp(".7z").zero?

    if LabsampleRelease.exists?(version: version)
      abort("A LabsampleRelease with version #{version} already exists.")
    end

    release = LabsampleRelease.new(version: version)
    release.archive.attach(io: File.open(archive_path), filename: File.basename(archive_path))
    release.save!

    puts "Created LabsampleRelease ##{release.id} (version #{release.version}) with archive #{File.basename(archive_path)}."
  end
end
