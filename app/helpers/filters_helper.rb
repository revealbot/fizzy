module FiltersHelper
  def filter_chip_id(value, name)
    "#{name}_filter--#{value}"
  end

  def filter_chip_frame_id(kind)
    "#{kind}_chips"
  end

  def filter_chips(filter, **)
    safe_join [
      chips_for_filter_kind(filter, :indexed_by, **),
      chips_for_filter_kind(filter, :tags, **),
      chips_for_filter_kind(filter, :assignees, **),
      chips_for_filter_kind(filter, :assigners, **),
      chips_for_filter_kind(filter, :buckets, **),
      chips_for_filter_kind(filter, :terms, **)
    ]
  end

  def filter_chips_for_editing(filter, **)
    safe_join [
      frame_for_filter_kind(filter, :indexed_by, **),
      frame_for_filter_kind(filter, :tags, **),
      frame_for_filter_kind(filter, :assignees, **),
      frame_for_filter_kind(filter, :assigners, **),
      frame_for_filter_kind(filter, :buckets, **),
      frame_for_filter_kind(filter, :terms, **)
    ]
  end

  def filter_chip_tag(display:, value:, name:, **options)
    tag.button id: filter_chip_id(value, name),
        class: [ "btn txt-small btn--remove", options.delete(:class) ],
        data: { action: "filter-form#removeFilter form#submit", filter_form_target: "button" } do
      concat hidden_field_tag(name, value, id: nil)
      concat tag.span(display)
      concat image_tag("close.svg", aria: { hidden: true }, size: 24)
    end
  end

  def button_to_chip(text, kind:, object:, data: {})
    if object
      button_to text, filter_chips_path, method: :post, class: "btn btn--plain filter__button", params: chip_attrs(kind, object), data: data
    else
      button_tag text, type: :button, class: "btn btn--plain filter__button", data: data
    end
  end

  private
    def chips_for_filter_kind(filter, kind, **)
      Array(filter.to_h[kind]).map do |value|
        if value.respond_to? :map
          safe_join value.map { |v| filter_chip_tag(**chip_attrs(kind, v), **) }
        else
          filter_chip_tag(**chip_attrs(kind, value), **)
        end
      end
    end

    def chip_attrs(kind, object)
      case kind&.to_sym
      when :tags
        [ object.hashtag, object.id, "tag_ids[]" ]
      when :buckets
        [ "in #{object.name}", object.id, "bucket_ids[]" ]
      when :assignees
        [ "for #{object.name}", object.id, "assignee_ids[]" ]
      when :assigners
        [ "by #{object.name}", object.id, "assigner_ids[]" ]
      when :indexed_by
        [ object.humanize, object, "indexed_by" ]
      when :assignments
        [ object.humanize, object, "assignments" ]
      when :terms
        [ %Q("#{object}"), object, "terms[]" ]
      end.then do |display, value, name|
        { display: display, value: value, name: name, frame: filter_chip_frame_id(kind) }
      end
    end

    def frame_for_filter_kind(filter, kind, **)
      chips_for_filter_kind(filter, kind, **).then do |chips|
        turbo_frame_tag filter_chip_frame_id(kind) do
          safe_join chips
        end
      end
    end
end
