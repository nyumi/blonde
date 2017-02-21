require 'test_helper'

class WatchListsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get watch_lists_index_url
    assert_response :success
  end

end
