class WatchListsController < ApplicationController
  def index
    @watch_lists = WatchListView.all
  end
end
