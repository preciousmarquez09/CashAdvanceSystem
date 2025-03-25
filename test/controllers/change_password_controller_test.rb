require 'test_helper'

class ChangePasswordControllerTest < ActionDispatch::IntegrationTest
  test "should get change_password" do
    get change_password_change_password_url
    assert_response :success
  end

end
