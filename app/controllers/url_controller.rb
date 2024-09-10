require "open-uri"

class UrlController < ApplicationController
  # Public endpoint, we do not worry about authn/z for now
  skip_before_action :verify_authenticity_token
  before_action :validate_create_params, only: :create
  after_action :track_redirects, only: :redirect

  def show
    hash = params[:hash]

    url = Url.find_by_hashed_url(hash)

    if url.nil?
      render json: { error: "Target URL hash does not exist" }, status: 404
      return
    end

    render json: url
  end

  def redirect
    hash = params[:hash]
    url = Url.find_by_hashed_url(hash)

    if url.nil?
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
      return
    end

    # NOTE: ALTHOUGH THIS SATISFIES THE BRAKEMAN STATIC ANALYZER, THIS BY NO MEANS GUARANTEES THAT THE REDIRECT IS SAFE
    # SINCE IT'S NOT FEASIBLE TO CHECK THAT A URL IS NON-MALICIOUS. THE BEST WAY TO MITIGATE THIS IS TO USE A BLACKLIST
    # OF KNOWN MALICIOUS URLS, OR EDUCATE USERS TO ONLY CLICK ON TRUSTED LINKS.
    uri = URI.parse(url.target_url)
    redirect_to uri.to_s, status: :moved_permanently, allow_other_host: true
  end

  def create
    target_url = params[:target_url]

    # URL is guaranteed to be valid due to validation in validate_create_params
    # We set a 1 second timeout for reading the target_url to prevent overly-long requests.
    # This is a huge bottleneck, since we are blocking the request until the target_url is successfully read.
    # Whether or not this is can be done asynchronously depends on the product requirements.
    html_title = "Unknown title"
    begin
      html_doc = Nokogiri::HTML(URI.open(target_url.to_s, read_timeout: 1))

      parsed_title = html_doc.css("title").text

      if parsed_title.is_a? String and !parsed_title.empty?
        html_title = parsed_title
      end
    rescue
      # Ignored since we already defaulting the value to "Unknown title" above
    end

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

  private

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

  # A possible improvement is to make this a background job, since the result of this does not matter
  # to the user and can be done asynchronously.
  # We only save the country here and ip address here, however this can be extended to save more information
  # such as lat/long. This is not a particularly extensible way to track visits,
  # something more robust would be a gem like Ahoy https://github.com/ankane/ahoy .
  # However, this comes at the cost of making the tracked information more generic, and we would be unable to index
  # on fields like the hashed_url.
  # Note that bot visits (eg. via curl, Postman, etc) are also tracked.
  def track_redirects
    # only track redirects for successful redirects
    if response.status != 301
      return
    end

    ip = request.remote_ip
    hashed_url = params[:hash]
    geolocation = Geocoder.search(ip)

    # If we cannot get the country, we default to "Unknown"
    if geolocation.first.country.nil?
      country = "Unknown"
    else
      country = geolocation.first.country
    end

    if HashedUrlVisit.new(hashed_url: hashed_url, ip: ip, country: country).save
      logger.info "Successfully saved visit for hashed_url #{hashed_url}"
    else
      logger.error "Failed to save visit for hashed_url #{hashed_url}"
    end
  end
end
