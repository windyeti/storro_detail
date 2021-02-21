require 'test_helper'

class AshantisControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get ashantis_index_url
    assert_response :success
  end

  test "should get import_ashanti" do
    get ashantis_import_ashanti_url
    assert_response :success
  end

end
