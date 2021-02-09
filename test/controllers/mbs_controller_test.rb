require 'test_helper'

class MbsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get mbs_index_url
    assert_response :success
  end

end
