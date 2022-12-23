require "test_helper"

class FilePushesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @file_push = file_pushes(:one)
  end

  test "should get index" do
    get file_pushes_url
    assert_response :success
  end

  test "should get new" do
    get new_file_push_url
    assert_response :success
  end

  test "should create file_push" do
    assert_difference("FilePush.count") do
      post file_pushes_url, params: { file_push: { deletable_by_viewer: @file_push.deletable_by_viewer, deleted: @file_push.deleted, expire_after_days: @file_push.expire_after_days, expire_after_views: @file_push.expire_after_views, expired: @file_push.expired, expired_on: @file_push.expired_on, note: @file_push.note, payload: @file_push.payload, retrieval_step: @file_push.retrieval_step, url_token: @file_push.url_token, user_id: @file_push.user_id } }
    end

    assert_redirected_to file_push_url(FilePush.last)
  end

  test "should show file_push" do
    get file_push_url(@file_push)
    assert_response :success
  end

  test "should get edit" do
    get edit_file_push_url(@file_push)
    assert_response :success
  end

  test "should update file_push" do
    patch file_push_url(@file_push), params: { file_push: { deletable_by_viewer: @file_push.deletable_by_viewer, deleted: @file_push.deleted, expire_after_days: @file_push.expire_after_days, expire_after_views: @file_push.expire_after_views, expired: @file_push.expired, expired_on: @file_push.expired_on, note: @file_push.note, payload: @file_push.payload, retrieval_step: @file_push.retrieval_step, url_token: @file_push.url_token, user_id: @file_push.user_id } }
    assert_redirected_to file_push_url(@file_push)
  end

  test "should destroy file_push" do
    assert_difference("FilePush.count", -1) do
      delete file_push_url(@file_push)
    end

    assert_redirected_to file_pushes_url
  end
end
