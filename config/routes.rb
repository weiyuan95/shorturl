Rails.application.routes.draw do
  get "/api/url/:hash" => "url#show"
  post "/api/url" => "url#create"

  get "/api/analytics/url/raw" => "analytics#url_visits_raw_data"
  get "/api/analytics/url/clicks" => "analytics#url_clicks"

  get "/:hash" => "url#redirect"
end
