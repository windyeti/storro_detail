require 'test_helper'

class VlsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get vls_index_url
    assert_response :success
  end

  test "should get import" do
    get vls_import_url
    assert_response :success
  end

  test "should get linking" do
    get vls_linking_url
    assert_response :success
  end

  test "should get syncronaize" do
    get vls_syncronaize_url
    assert_response :success
  end

  test "should get import_linking_syncronaize" do
    get vls_import_linking_syncronaize_url
    assert_response :success
  end

  test "should get unlinking_to_xls" do
    get vls_unlinking_to_xls_url
    assert_response :success
  end

end
