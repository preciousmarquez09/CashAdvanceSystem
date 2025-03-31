require 'test_helper'

class RepaymentSchedulesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get repayment_schedules_index_url
    assert_response :success
  end

end
