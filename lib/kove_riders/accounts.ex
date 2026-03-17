defmodule KoveRiders.Accounts do
  import Ecto.Query, warn: false
  alias KoveRiders.Repo
  alias KoveRiders.Accounts.{User, UserToken, UserNotifier}

  def get_user_by_email(email) when is_binary(email), do: Repo.get_by(User, email: email)
  def get_user_by_handle(handle) when is_binary(handle), do: Repo.get_by(User, handle: handle)

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  def register_user(attrs) do
    handle = generate_unique_handle(Map.get(attrs, "email") || Map.get(attrs, :email) || "")

    %User{}
    |> User.email_changeset(attrs)
    |> Ecto.Changeset.put_change(:handle, handle)
    |> Repo.insert()
  end

  def register_or_login_with_google(%{email: email, google_id: google_id}) do
    case Repo.get_by(User, google_id: google_id) do
      %User{} = user ->
        {:ok, user}

      nil ->
        case Repo.get_by(User, email: email) do
          nil ->
            handle = generate_unique_handle(email)

            %User{}
            |> User.google_registration_changeset(%{email: email, google_id: google_id})
            |> Ecto.Changeset.put_change(:handle, handle)
            |> Repo.insert()

          %User{} = existing_user ->
            existing_user
            |> Ecto.Changeset.change(%{google_id: google_id})
            |> Repo.update()
        end
    end
  end

  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  def change_user_email(user, attrs \\ %{}, opts \\ []),
    do: User.email_changeset(user, attrs, opts)

  def change_user_handle(user, attrs \\ %{}, opts \\ []),
    do: User.handle_changeset(user, attrs, opts)

  @doc """
  Updates the rider handle. Max #{2} changes total.
  Returns {:error, :locked} when the limit is reached.
  """
  def update_user_handle(user, attrs) do
    if User.handle_locked?(user) do
      {:error, :locked}
    else
      user
      |> User.handle_changeset(attrs)
      |> Ecto.Changeset.put_change(:handle_change_count, (user.handle_change_count || 0) + 1)
      |> Repo.update()
    end
  end

  def generate_unique_handle(email) do
    base = User.handle_from_email(email)
    base = if String.length(base) < 3, do: "rider", else: base
    base = String.slice(base, 0, 25)
    suffix = :rand.uniform(9999) |> Integer.to_string() |> String.pad_leading(4, "0")
    "#{base}_#{suffix}"
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  def change_user_password(user, attrs \\ %{}, opts \\ []),
    do: User.password_changeset(user, attrs, opts)

  def update_user_password(user, attrs) do
    user |> User.password_changeset(attrs) |> update_user_and_delete_all_tokens()
  end

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise "magic link log in is not allowed for unconfirmed users with a password set!"

      {%User{confirmed_at: nil} = user, _token} ->
        user |> User.confirm_changeset() |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")
    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  def generate_magic_link_token(%User{} = user) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    encoded_token
  end

  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        Repo.delete_all(from(t in UserToken, where: t.user_id == ^user.id))
        {:ok, {user, []}}
      end
    end)
  end
end
