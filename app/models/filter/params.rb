module Filter::Params
  extend ActiveSupport::Concern

  PERMITTED_PARAMS = [ :indexed_by, :assignments, bucket_ids: [], assignee_ids: [], tag_ids: [], terms: [] ]

  included do
    before_save { self.params_digest = self.class.digest_params(as_params) }
  end

  def as_params
    @as_params ||= to_h.dup.tap do |h|
      h["tag_ids"] = h.delete("tags")&.ids
      h["bucket_ids"] = h.delete("buckets")&.ids
      h["assignee_ids"] = h.delete("assignees")&.ids
    end.compact_blank.with_indifferent_access
  end

  def to_h
    @to_h ||= {}.tap do |h|
      h["tags"] = tags
      h["terms"] = terms
      h["buckets"] = buckets
      h["assignees"] = assignees
      h["indexed_by"] = indexed_by
      h["assignments"] = assignments
    end.reject do |k, v|
      default_fields[k] == v
    end.compact_blank.with_indifferent_access
  end

  def to_params
    ActionController::Parameters.new(as_params).permit(*PERMITTED_PARAMS).tap do |params|
      params[:filter_id] = id if persisted?
    end
  end
end
