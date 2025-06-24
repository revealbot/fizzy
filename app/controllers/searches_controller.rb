class SearchesController < ApplicationController
  MAX_RESULTS = 50

  def show
    @search = Search.new(Current.user, query_param)
  end

  private
    def query_param
      params[:q]
    end
end
