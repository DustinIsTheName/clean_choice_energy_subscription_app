require_relative 'boot'

require 'rails/all'
require 'csv'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CleanChoiceEnergySubscriptionApp
  class Application < Rails::Application

    config.autoload_paths += %W(#{config.root}/lib/functions)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    ShopifyAPI::Base.site = "https://#{ENV["API_KEY"]}:#{ENV["PASSWORD"]}@#{ENV["SHOPIFY_URL"]}/admin"
  end
end
