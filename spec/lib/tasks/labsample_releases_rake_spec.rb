require 'rails_helper'
require 'rake'

RSpec.describe 'labsample_releases:add' do
  let(:archive_path) { Rails.root.join('tmp', "release-spec-#{SecureRandom.hex(4)}.7z").to_s }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task['labsample_releases:add'].reenable
    File.write(archive_path, "fake archive contents")
  end

  after do
    File.delete(archive_path) if File.exist?(archive_path)
  end

  it 'creates a LabsampleRelease with the archive attached' do
    expect {
      Rake::Task['labsample_releases:add'].invoke("1.2.3", archive_path)
    }.to change { LabsampleRelease.count }.by(1)

    release = LabsampleRelease.find_by(version: "1.2.3")
    expect(release.archive).to be_attached
    expect(release.archive.filename.to_s).to eq(File.basename(archive_path))
  end

  it 'aborts when the version already exists' do
    create(:labsample_release, version: "1.2.3")

    expect {
      Rake::Task['labsample_releases:add'].invoke("1.2.3", archive_path)
    }.to raise_error(SystemExit).and change { LabsampleRelease.count }.by(0)
  end

  it 'aborts when the file does not exist' do
    expect {
      Rake::Task['labsample_releases:add'].invoke("1.2.4", "/tmp/does-not-exist-#{SecureRandom.hex(4)}.7z")
    }.to raise_error(SystemExit)
  end

  it 'aborts when the file is not a .7z archive' do
    wrong_ext_path = archive_path.sub(".7z", ".zip")
    File.write(wrong_ext_path, "fake contents")

    expect {
      Rake::Task['labsample_releases:add'].invoke("1.2.5", wrong_ext_path)
    }.to raise_error(SystemExit)
  ensure
    File.delete(wrong_ext_path) if wrong_ext_path && File.exist?(wrong_ext_path)
  end
end
