module Card::Triageable
  extend ActiveSupport::Concern

  included do
    belongs_to :column, optional: true

    scope :awaiting_triage, -> { active.where.missing(:column) }
    scope :triaged, -> { active.joins(:column) }
  end

  def triaged?
    active? && column.present?
  end

  def awaiting_triage?
    active? && !triaged?
  end

  def triage_into(column)
    raise "The column must belong to the card collection" unless collection == column.collection

    transaction do
      resume
      update! column: column
    end
  end

  def send_back_to_triage
    transaction do
      resume
      update! column: nil
    end
  end
end
