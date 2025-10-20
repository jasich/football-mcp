# frozen_string_literal: true

class AssetsController < ApplicationController
  # Serve JavaScript bundles through Rails to ensure CORS headers are applied
  def javascript
    file_path = Rails.root.join("public/assets/application.js")

    if File.exist?(file_path)
      send_file file_path,
        type: "text/javascript",
        disposition: "inline",
        filename: "application.js"
    else
      head :not_found
    end
  end

  # Serve sourcemap files
  def sourcemap
    file_path = Rails.root.join("public/assets/application.js.map")

    if File.exist?(file_path)
      send_file file_path,
        type: "application/json",
        disposition: "inline",
        filename: "application.js.map"
    else
      head :not_found
    end
  end
end
