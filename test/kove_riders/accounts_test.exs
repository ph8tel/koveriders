defmodule KoveRiders.AccountsTest do
  use KoveRiders.DataCase, async: true

  alias KoveRiders.Accounts
  alias KoveRiders.Accounts.User

  describe "register_user/1" do
    test "creates a user with valid attrs" do
      assert {:ok, %User{} = user} = Accounts.register_user(%{email: "new@example.com"})
      assert user.email == "new@example.com"
    end

    test "returns error on duplicate email" do
      insert(:user, email: "dup@example.com")
      assert {:error, changeset} = Accounts.register_user(%{email: "dup@example.com"})
      assert "has already been taken" in errors_on(changeset).email
    end
  end

  describe "update_user_handle/2" do
    test "sets handle and increments change count" do
      user = insert(:user, handle: "oldrider", handle_change_count: 0)
      assert {:ok, updated} = Accounts.update_user_handle(user, %{handle: "newrider"})
      assert updated.handle == "newrider"
      assert updated.handle_change_count == 1
    end

    test "rejects reserved handle" do
      user = insert(:user)
      assert {:error, cs} = Accounts.update_user_handle(user, %{handle: "admin"})
      assert "is reserved" in errors_on(cs).handle
    end

    test "rejects handle with invalid chars" do
      user = insert(:user)
      assert {:error, cs} = Accounts.update_user_handle(user, %{handle: "Bad Handle!"})
      assert errors_on(cs).handle != []
    end

    test "allows exactly 2 changes" do
      user = insert(:user, handle_change_count: 1)
      assert {:ok, updated} = Accounts.update_user_handle(user, %{handle: "secondchange"})
      assert updated.handle_change_count == 2
    end

    test "blocks change after limit reached" do
      user = insert(:user, handle_change_count: 2)
      assert {:error, :locked} = Accounts.update_user_handle(user, %{handle: "shouldfail"})
    end
  end

  describe "generate_user_session_token/1 and get_user_by_session_token/1" do
    test "round-trips a token" do
      user = insert(:user)
      token = Accounts.generate_user_session_token(user)
      assert {fetched_user, _inserted_at} = Accounts.get_user_by_session_token(token)
      assert fetched_user.id == user.id
    end

    test "returns nil for unknown token" do
      assert nil == Accounts.get_user_by_session_token(:crypto.strong_rand_bytes(32))
    end
  end

  describe "get_user_by_email/1" do
    test "returns nil for missing email" do
      assert nil == Accounts.get_user_by_email("nope@example.com")
    end

    test "returns user for known email" do
      user = insert(:user)
      assert found = Accounts.get_user_by_email(user.email)
      assert found.id == user.id
    end
  end
end
