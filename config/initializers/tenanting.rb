Rails.application.config.after_initialize do
  # in production and staging, we're using a two-level subdomain like "tenant.fizzy.37signals.com".
  # in development and beta it's only a single-level subdomain.
  Rails.application.config.active_record_tenanted.tenant_resolver = ->(request) do
    next nil if request.path == "/up"

    tld_length = [ "37signals.com", "37signals-staging.com" ].include?(request.domain) ? 2 : 1
    request.subdomain(tld_length).presence || "return-404" # this is a quick fix for now
  end
end

ActiveSupport.on_load(:action_controller_base) do
  before_action { logger.struct tenant: ApplicationRecord.current_tenant }
end
