# frozen_string_literal: true

# This file is prefixed with 0_ since initializers are loaded in alphabetical order.

%w[DB_USERNAME DB_PASSWORD DB_HOST DB_NAME].each do |env_var|
  raise "Missing environment variable: #{env_var}" unless ENV.key?(env_var)
end
