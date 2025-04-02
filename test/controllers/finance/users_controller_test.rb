require 'test_helper'

class Finance::UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get finance_users_index_url
    assert_response :success
  end

  test "should get show" do
    get finance_users_show_url
    assert_response :success
  end

end
