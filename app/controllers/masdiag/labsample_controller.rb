module Masdiag
  # Odpytywane przez LabSample.Updater przed każdym uruchomieniem okna logowania,
  # żeby sprawdzić czy jest dostępna nowsza wersja aplikacji desktopowej.
  class LabsampleController < ApplicationController
    # GET /masdiag/labsample/latest_version
    def latest_version
      json_response({ version: LabsampleRelease.latest&.version })
    end

    # GET /masdiag/labsample/download_url
    def download_url
      release = LabsampleRelease.latest

      return json_response({ url: nil }) unless release&.archive&.attached?

      json_response({ url: rails_blob_url(release.archive, host: request.base_url) })
    end
  end
end
