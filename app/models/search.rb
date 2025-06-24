class Search
  attr_reader :user, :query, :max_results

  def self.table_name_prefix
    "search_"
  end

  def initialize(user, query, max_results: 50)
    @user = user
    @query = Query.new(query)
    @max_results = max_results
  end

  def results
    return [] unless query.valid?

    cards = user.accessible_cards.search(query)
      .select([
        "cards.id as card_id",
        "highlight(cards_search_index, 0, '<mark class=\"circled-text\"><span></span>', '</mark>') AS card_title",
        "snippet(cards_search_index, 1, '<mark class=\"circled-text\"><span></span>', '</mark>', '...', 20) AS card_description",
        "null as comment_body",
        "collections.name as collection_name",
        "cards.creator_id",
        "'card' as source",
        "bm25(cards_search_index, 10.0, 2.0) AS score"
      ].join(","))

    comments = user.accessible_comments.search(query)
      .select([
        "comments.card_id as card_id",
        "cards.title AS card_title",
        "null AS card_description",
        "snippet(comments_search_index, 0, '<mark class=\"circled-text\"><span></span>', '</mark>', '...', 20) AS comment_body",
        "collections.name as collection_name",
        "comments.creator_id",
        "'comment' as source",
        "bm25(comments_search_index, 1.0) AS score"
      ].join(","))

    union_sql = "(#{cards.to_sql} UNION #{comments.to_sql}) as search_results"
    Search::Result.from(union_sql).order(score: :desc).limit(max_results)
  end
end
