defmodule KoveRiders.UserBikesTest do
  use KoveRiders.DataCase, async: true

  alias KoveRiders.UserBikes
  alias KoveRiders.Accounts.Scope

  describe "create_user_bike/2" do
    test "creates a bike with valid attrs" do
      user = insert(:user)
      scope = Scope.for_user(user)

      assert {:ok, bike} =
               UserBikes.create_user_bike(scope, %{model: "800x_pro", year: 2024})

      assert bike.model == "800x_pro"
      assert bike.year == 2024
      assert bike.user_id == user.id
    end

    test "fails with invalid model" do
      user = insert(:user)
      scope = Scope.for_user(user)

      assert {:error, cs} =
               UserBikes.create_user_bike(scope, %{model: "unicorn", year: 2024})

      assert errors_on(cs).model != []
    end

    test "fails with out-of-range year" do
      user = insert(:user)
      scope = Scope.for_user(user)

      assert {:error, cs} =
               UserBikes.create_user_bike(scope, %{model: "800x_pro", year: 1990})

      assert errors_on(cs).year != []
    end
  end

  describe "list_user_bikes/1" do
    test "returns only the user's bikes" do
      user = insert(:user)
      other = insert(:user)
      insert(:user_bike, user: user, model: "800x_pro")
      insert(:user_bike, user: other, model: "mx250")

      bikes = UserBikes.list_user_bikes(Scope.for_user(user))
      assert length(bikes) == 1
      assert hd(bikes).model == "800x_pro"
    end
  end

  describe "update_user_bike/3" do
    test "updates attributes" do
      user = insert(:user)
      scope = Scope.for_user(user)
      bike = insert(:user_bike, user: user)

      assert {:ok, updated} =
               UserBikes.update_user_bike(scope, bike.id, %{nickname: "Dusty"})

      assert updated.nickname == "Dusty"
    end
  end

  describe "delete_user_bike/2" do
    test "removes the bike" do
      user = insert(:user)
      scope = Scope.for_user(user)
      bike = insert(:user_bike, user: user)

      assert {:ok, _} = UserBikes.delete_user_bike(scope, bike.id)

      assert_raise Ecto.NoResultsError, fn ->
        UserBikes.get_user_bike!(scope, bike.id)
      end
    end
  end

  describe "add_mod/3 and list_mods/1" do
    test "creates a mod on the bike" do
      user = insert(:user)
      scope = Scope.for_user(user)
      bike = insert(:user_bike, user: user)

      assert {:ok, mod} =
               UserBikes.add_mod(scope, bike.id, %{
                 category: "exhaust",
                 title: "Akrapovic full system"
               })

      assert mod.title == "Akrapovic full system"
      mods = UserBikes.list_mods(bike.id)
      assert Enum.any?(mods, &(&1.id == mod.id))
    end

    test "fails with missing title" do
      user = insert(:user)
      scope = Scope.for_user(user)
      bike = insert(:user_bike, user: user)

      assert {:error, cs} = UserBikes.add_mod(scope, bike.id, %{category: "exhaust"})
      assert errors_on(cs).title != []
    end
  end

  describe "delete_mod/2" do
    test "removes the mod" do
      user = insert(:user)
      scope = Scope.for_user(user)
      bike = insert(:user_bike, user: user)
      mod = insert(:user_bike_mod, user_bike: bike)

      assert {:ok, _} = UserBikes.delete_mod(scope, mod.id)
      assert UserBikes.list_mods(bike.id) == []
    end
  end

  describe "add_image/3" do
    test "creates an image record" do
      user = insert(:user)
      scope = Scope.for_user(user)
      bike = insert(:user_bike, user: user)

      attrs = %{r2_key: "bike-photos/abc.jpg", url: "/uploads/bike-photos/abc.jpg"}
      assert {:ok, img} = UserBikes.add_image(scope, bike.id, attrs)
      assert img.r2_key == "bike-photos/abc.jpg"
    end
  end

  describe "delete_image/2" do
    test "removes the image record" do
      user = insert(:user)
      scope = Scope.for_user(user)
      bike = insert(:user_bike, user: user)
      img = insert(:user_bike_image, user_bike: bike)

      assert {:ok, _deleted} = UserBikes.delete_image(scope, img.id)
      assert UserBikes.list_images(bike.id) == []
    end
  end
end
