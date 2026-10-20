require "rack/cors"

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://ayshelled.github.io", "http://127.0.0.1:5500"

    resource "/api/v1/services*",
      headers: %w[accept content-type],
      methods: %i[get]
  end
end
