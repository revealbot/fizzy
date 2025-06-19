Queenbee.host_app = Fizzy

Rails.application.config.to_prepare do
  Queenbee::Subscription.short_names = Subscription::SHORT_NAMES
  Queenbee::ApiToken.token = Rails.application.credentials.dig(:queenbee_api_token)
end
