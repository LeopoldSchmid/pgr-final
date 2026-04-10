require "test_helper"

class Api::FoodItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "food-items-api@example.com", password: "password123", locale: "en")
    FoodItem.create!(name: "Tomatoes", standard_unit: "kg", category: "produce", unit_type: "weight")
    FoodItem.create!(name: "Tomato paste", standard_unit: "kg", category: "pantry", unit_type: "weight")
    FoodItem.create!(name: "Beer", standard_unit: "l", category: "other", unit_type: "volume")

    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "search finds plural item from singular query" do
    get "/api/food_items/search", params: { q: "tomato" }

    assert_response :success
    body = JSON.parse(response.body)
    names = body.map { |item| item["name"] }

    assert_includes names, "Tomatoes"
    assert_includes names, "Tomato paste"
  end
end
