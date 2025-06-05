require_relative "production"

Rails.application.configure do
  config.action_mailer.default_url_options = { host: "%{tenant}.fizzy.37signals-staging.com" }
end
