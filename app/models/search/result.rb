class Search::Result < ApplicationRecord
  def source
    self[:source]&.inquiry
  end

  def creator
    User.find(creator_id)
  end

  def readonly?
    true
  end
end
