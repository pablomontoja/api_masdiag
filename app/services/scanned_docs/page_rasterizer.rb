require "open3"
require "tmpdir"
require "fileutils"

module ScannedDocs
  class PageRasterizer
    DPI = 200

    def initialize(attachment)
      @attachment = attachment
    end

    def to_png_bytes
      @attachment.open do |pdf|
        dir  = Dir.mktmpdir
        base = File.join(dir, "page")
        _out, err, status = Open3.capture3(
          "pdftoppm", "-png", "-r", DPI.to_s, "-singlefile", pdf.path, base
        )
        raise "rasterize failed: #{err}" unless status.success?
        File.binread("#{base}.png")
      ensure
        FileUtils.remove_entry(dir) if dir && File.directory?(dir)
      end
    end
  end
end
