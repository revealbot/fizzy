module Bucket::View::Summarized
  def summary
    [ order_by_summary, status_summary, tag_summary, assignee_summary ].compact.to_sentence.upcase_first
  end

  private
    delegate :to_sentence, to: "ApplicationController.helpers", private: true

    def order_by_summary
      Bucket::View::ORDERS.fetch order_by, nil
    end

    def status_summary
      Bucket::View::STATUSES.fetch status, nil
    end

    def assignee_summary
      "assigned to <mark>#{assignees.pluck(:name).to_choice_sentence}</mark>" if assignees.any?
    end

    def tag_summary
      "tagged <mark>#{tags.map(&:hashtag).to_choice_sentence}</mark>" if tags.any?
    end
end
