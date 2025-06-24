module ApplicationHelper
  def page_title_tag
    tag.title @page_title || "Fizzy"
  end

  def icon_tag(name, **options)
    tag.span class: class_names("icon icon--#{name}", options.delete(:class)), "aria-hidden": true, **options
  end

  def circled_text(text, **options)
    tag.mark(class: class_names("circled-text", options.delete(:class)), **options) do
      concat text
      concat(tag.span("", "aria-hidden": true))
    end
  end
end
