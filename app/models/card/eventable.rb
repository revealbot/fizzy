module Card::Eventable
  extend ActiveSupport::Concern

  include ::Eventable

  included do
    before_create { self.last_active_at = Time.current }

    after_save :track_title_change, if: :saved_change_to_title?
  end

  def event_was_created(event)
    transaction do
      create_system_comment_for(event)
      touch(:last_active_at)
    end
  end

  private
    def should_track_event?
      published?
    end

    def find_or_capture_event_summary
      messages.last&.event_summary || capture(EventSummary.new).event_summary
    end

    def track_title_change
      if title_before_last_save.present?
        track_event "title_changed", particulars: { old_title: title_before_last_save, new_title: title }
      end
    end

    def create_system_comment_for(event)
      SystemCommenter.new(self, event).comment
    end
end
