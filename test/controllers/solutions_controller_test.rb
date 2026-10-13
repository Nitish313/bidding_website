require 'test_helper'

class SolutionsControllerTest < ActionDispatch::IntegrationTest
  test "my_solutions redirects to login when logged out" do
    get my_solutions_path
    assert_redirected_to login_path
  end
end
