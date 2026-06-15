require "net/http"
require "json"
require "base64"

module ScannedDocs
  class OcrClient
    PROMPT = "Please perform OCR on the input image and output the result as " \
             "GitHub-flavored Markdown. Preserve headings, tables and lists. " \
             "Output only the Markdown, no explanations."

    def initialize(endpoint: ENV.fetch("OCR_ENDPOINT", "http://127.0.0.1:8080/v1/chat/completions"))
      @endpoint = URI(endpoint)
    end

    def transcribe(png_bytes)
      image_url = "data:image/png;base64,#{Base64.strict_encode64(png_bytes)}"
      payload = {
        messages: [{
          role: "user",
          content: [
            { type: "image_url", image_url: { url: image_url } },
            { type: "text", text: PROMPT }
          ]
        }],
        temperature: 0.1,
        max_tokens: 4096
      }

      req = Net::HTTP::Post.new(@endpoint)
      req["Content-Type"] = "application/json"
      req.body = payload.to_json

      res = Net::HTTP.start(@endpoint.host, @endpoint.port, read_timeout: 600) { |h| h.request(req) }
      raise "OCR server error #{res.code}" unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body).dig("choices", 0, "message", "content").to_s.strip
    end
  end
end
