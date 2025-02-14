require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module InstaClone
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    credentials.config.each do |key, value|
      if key.to_s == Rails.env
        value.each do |env_key, env_value|
          ENV[env_key.to_s.upcase] = env_value.to_s if ENV[env_key.to_s.upcase].blank?
          ENV[env_key.to_s.downcase] = env_value.to_s if ENV[env_key.to_s.downcase].blank?
        end
      elsif ["development", "staging", "test", "production"].include?(key.to_s) == false
        if value.is_a?(Hash)
          value.each do |env_key, env_value|
            ENV[env_key.to_s.upcase] = env_value.to_s if ENV[env_key.to_s.upcase].blank?
            ENV[env_key.to_s.downcase] = env_value.to_s if ENV[env_key.to_s.downcase].blank?
          end
        else
          ENV[key.to_s.upcase] = value.to_s if ENV[key.to_s.upcase].blank?
          ENV[key.to_s.downcase] = value.to_s if ENV[key.to_s.downcase].blank?
        end
      end
    end


    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
