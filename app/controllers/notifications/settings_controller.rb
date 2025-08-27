class Notifications::SettingsController < ApplicationController
  include FilterScoped

  enable_collection_filtering only: :show

  def show
    @collections = Current.user.collections.alphabetically
  end
end
