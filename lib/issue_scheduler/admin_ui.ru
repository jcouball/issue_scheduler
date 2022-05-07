# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

# Run the admin UI from the command line using:
#   $ rackup admin_ui.rb

# A Web process always runs as client, no need to configure server
Sidekiq.configure_client do |config|
  config.redis = { db: 1 }
end

# Sidekiq::Client.push('class' => "HardWorker", 'args' => [])

# In a multi-process deployment, all Web UI instances should share
# this secret key so they can all decode the encrypted browser cookies
# and provide a working session.
# Rails does this in /config/initializers/secret_token.rb
secret_key = SecureRandom.hex(32)
use Rack::Session::Cookie, secret: secret_key, same_site: true, max_age: 86_400

run Sidekiq::Web
