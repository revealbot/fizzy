class Card::Eventable::SystemCommenter
  attr_reader :card, :event

  def initialize(card, event)
    @card, @event = card, event
  end

  def comment
    return unless comment_body.present?
    if comment = find_replaceable_system_comment
      comment.update! body: comment_body
    else
      card.comments.create! creator: User.system, body: comment_body
    end
  end

  private
    REPLACEABLE_EVENTS = [
      %w[ card_assigned card_unassigned ]
    ]

    def comment_body
      case event.action
      when "card_assigned"
        "Assigned to #{card.assignees.pluck(:name).to_sentence}."
      when "card_unassigned"
        if card.assignees.empty?
          "Unassigned from #{event.assignees.pluck(:name).to_sentence}."
        else
          "Assigned to #{card.assignees.pluck(:name).to_sentence}."
        end
      when "card_staged"
        "#{event.creator.name} moved this to '#{event.stage_name}'."
      when "card_closed"
        "Closed by #{ event.creator.name }"
      when "card_title_changed"
        "#{event.creator.name} changed title from '#{event.particulars.dig('particulars', 'old_title')}' to '#{event.particulars.dig('particulars', 'new_title')}'."
      end
    end

    def find_replaceable_system_comment
      previous_comment, previous_event = card.comments.last, card.events[-2]
      if previous_comment&.creator&.system? && replaceable_event?(previous_event, event)
        previous_comment
      end
    end

    def replaceable_event?(candidate_event, replacement_event)
      candidate_event && replacement_event &&
        (candidate_event.action == replacement_event.action || REPLACEABLE_EVENTS.find { |related_actions| related_actions.include?(candidate_event.action) && related_actions.include?(replacement_event.action) })
    end
end
