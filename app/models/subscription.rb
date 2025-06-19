class Subscription < Queenbee::Subscription
  SHORT_NAMES = %w[ FreeV1 ]
end

class FreeV1Subscription < Subscription
  property :proper_name,  "Free Subscription"
  property :price,        0
  property :frequency,    "yearly"
end
