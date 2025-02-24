class Bubbles::WatchesController < ApplicationController
  include BubbleScoped, BucketScoped

  def show
    @watchers = @bubble.watchers.without(Current.user)
  end

  def create
    set_watching_and_redirect(true)
  end

  def destroy
    set_watching_and_redirect(false)
  end

  private
    def set_watching_and_redirect(watching)
      @bubble.set_watching(Current.user, watching)
      redirect_to bucket_bubble_watch_path(@bucket, @bubble)
    end
end
