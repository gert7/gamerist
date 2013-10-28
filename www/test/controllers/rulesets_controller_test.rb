require 'test_helper'

class RulesetsControllerTest < ActionController::TestCase
  setup do
    @ruleset = rulesets(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:rulesets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ruleset" do
    assert_difference('Ruleset.count') do
      post :create, ruleset: { map_id: @ruleset.map_id, playercount: @ruleset.playercount }
    end

    assert_redirected_to ruleset_path(assigns(:ruleset))
  end

  test "should show ruleset" do
    get :show, id: @ruleset
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @ruleset
    assert_response :success
  end

  test "should update ruleset" do
    patch :update, id: @ruleset, ruleset: { map_id: @ruleset.map_id, playercount: @ruleset.playercount }
    assert_redirected_to ruleset_path(assigns(:ruleset))
  end

  test "should destroy ruleset" do
    assert_difference('Ruleset.count', -1) do
      delete :destroy, id: @ruleset
    end

    assert_redirected_to rulesets_path
  end
end
