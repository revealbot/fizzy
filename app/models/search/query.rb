class Search::Query
  attr_reader :terms

  class << self
    def wrap(query)
      if query.is_a?(self)
        self.new(query)
      else
        query
      end
    end
  end

  def initialize(terms)
    @terms = sanitize_query_syntax(terms)
  end

  def valid?
    @terms.present?
  end

  alias to_s terms

  private
    def sanitize_query_syntax(terms)
      terms = terms.to_s
      terms = remove_invalid_search_characters(terms)
      terms = remove_unbalanced_quotes(terms)
      terms.presence
    end

    def remove_invalid_search_characters(terms)
      terms.gsub(/[^\w"]/, " ")
    end

    def remove_unbalanced_quotes(terms)
      if terms.count("\"").even?
        terms
      else
        terms.gsub("\"", " ")
      end
    end
end
