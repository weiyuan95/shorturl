# frozen_string_literal: true

class AnalyticsController < ApplicationController
  def url_visits_raw_data
    # Return all the hash url visits as json. This essentially returns the entire table as json, and shouldn't
    # be used on a sufficiently large table. If there really is a requirement to return all the data, pagination
    # should be implemented.
    # TODO: pagination
    begin
      render json: { raw_data: HashedUrlVisit.all }, status: 200
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end

  def url_clicks
    begin
      # return the number of visits to each hashed_url
      render json: { clicks: HashedUrlVisit.group("hashed_url").count }, status: 200
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end
end
