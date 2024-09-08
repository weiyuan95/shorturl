require "open-uri"

class UrlController < ApplicationController
  # Public endpoint, we do not worry about authn/z for now
  skip_before_action :verify_authenticity_token
  before_action :validate_create_params, only: :create

  def show
    hash = params[:hash]

    url = Url.find_by_hashed_url(hash)

    if url.nil?
      render json: { error: "Target URL hash does not exist" }, status: 404
      return
    end

    render json: { target_url: url.target_url, title: url.title, hashed_url: url.hashed_url }
  end

  def redirect
    hash = params[:hash]
    url = Url.find_by_hashed_url(hash)

    if url.nil?
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
      return
    end

    redirect_to url.target_url, status: :moved_permanently, allow_other_host: true
  end

  def create
    target_url = params[:target_url]

    # html is guaranteed to be valid due to validation in validate_create_params
    html_doc = Nokogiri::HTML(URI.open(target_url.to_s))
    html_title = html_doc.css("title").text

    begin
      hashed_url = Sha256UrlHasher.hash_url(target_url.to_s)
    rescue ArgumentError
      # should never hit this case, but we code defensively
      render json: { error: "Invalid target_url provided" }, status: 400
      return
    rescue RuntimeError => e
      logger.error "Unexpected error when hashing target_url #{e.message}"
      render json: { error: "Failed to hash target_url" }, status: 500
      return
    end

    new_url = Url.new(target_url: hashed_url.target_url, hashed_url: hashed_url.hashed_url, salt: hashed_url.salt, title: html_title)

    if new_url.invalid?
      render json: { error: new_url.errors.full_messages }, status: 400
      return
    end

    begin
      new_url.save!
      render json: new_url, status: 200
    rescue e
      logger.error e.message
      render json: { error: "Failed to save URL" }, status: 500
    end
  end

  def validate_create_params
    target_url = params[:target_url]

    if target_url.nil?
      render json: { error: "Target URL is required" }, status: 422
      return false
    end

    begin
      UrlHasher.validate(target_url.to_s)
    rescue ArgumentError
      render json: { error: "Invalid target_url provided" }, status: 422
    end

    true
  end
end
