require 'test_helper'

class SolutionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get solutions_new_url
    assert_response :success
  end

end
