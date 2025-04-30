require "test_helper"

class Card::Eventable::SystemCommenterTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
    @card = cards(:text)
  end

  test "card_assigned" do
    assert_system_comment "Assigned to Kevin" do
      @card.toggle_assignment users(:kevin)
    end
  end

  test "card_unassigned" do
    @card.toggle_assignment users(:kevin)
    @card.comments.destroy_all # To skip deduplication logic

    assert_system_comment "Unassigned from Kevin" do
      @card.toggle_assignment users(:kevin)
    end
  end

  test "card_staged" do
    assert_system_comment "David moved this to 'In progress'" do
      @card.change_stage_to workflow_stages(:qa_in_progress)
    end
  end

  test "card_closed" do
    assert_system_comment "Closed by David" do
      @card.close
    end
  end

  test "card_title_changed" do
    assert_system_comment "David changed title from 'The text is too small' to 'Make text larger'" do
      @card.update! title: "Make text larger"
    end
  end

  test "don't duplicate comments for the same kind of events" do
    @card.change_stage_to workflow_stages(:qa_in_progress)

    assert_no_difference -> { @card.comments.count } do
      @card.reload.change_stage_to workflow_stages(:qa_on_hold)
      assert_match /David moved this to 'On hold'/i, @card.comments.last.body.to_plain_text
    end
  end

  test "don't duplicate comments for related events" do
    @card.toggle_assignment users(:kevin)

    assert_no_difference -> { @card.comments.count } do
      @card.reload.toggle_assignment users(:kevin)
      assert_match /Unassigned from Kevin/i, @card.comments.last.body.to_plain_text
    end
  end

  private
    def assert_system_comment(expected_comment)
      assert_difference -> { @card.comments.count }, 1 do
        yield
        assert @card.comments.last.creator.system?
        assert_match Regexp.new(expected_comment.strip, Regexp::IGNORECASE), @card.comments.last.body.to_plain_text.strip
      end
    end
end
