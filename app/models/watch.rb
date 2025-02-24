class Watch < ApplicationRecord
  belongs_to :user
  belongs_to :bubble

  scope :watching, -> { where(watching: true) }
end
