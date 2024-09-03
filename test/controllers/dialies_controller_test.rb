require "test_helper"

class DialiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dialy = dialies(:one)
  end

  test "should get index" do
    get dialies_url
    assert_response :success
  end

  test "should get new" do
    get new_dialy_url
    assert_response :success
  end

  test "should create dialy" do
    assert_difference("Dialy.count") do
      post dialies_url, params: { dialy: { date: @dialy.date, text: @dialy.text, title: @dialy.title } }
    end

    assert_redirected_to dialy_url(Dialy.last)
  end

  test "should show dialy" do
    get dialy_url(@dialy)
    assert_response :success
  end

  test "should get edit" do
    get edit_dialy_url(@dialy)
    assert_response :success
  end

  test "should update dialy" do
    patch dialy_url(@dialy), params: { dialy: { date: @dialy.date, text: @dialy.text, title: @dialy.title } }
    assert_redirected_to dialy_url(@dialy)
  end

  test "should destroy dialy" do
    assert_difference("Dialy.count", -1) do
      delete dialy_url(@dialy)
    end

    assert_redirected_to dialies_url
  end
end
