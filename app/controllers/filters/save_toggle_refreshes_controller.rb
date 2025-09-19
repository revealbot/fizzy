class Filters::SaveToggleRefreshesController < ApplicationController
  include FilterScoped

  def create
    turbo_stream.replace("filter-toggle", partial: "filters/filter_toggle", locals: { filter: @filter })
  end
end
