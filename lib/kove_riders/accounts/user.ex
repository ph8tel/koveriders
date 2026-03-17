defmodule KoveRiders.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @max_handle_changes 2

  @reserved_handles ~w(home garage users settings auth admin privacy support
    help about contact api riders r www koveriders)

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    field :google_id, :string
    field :handle, :string
    field :handle_change_count, :integer, default: 0

    has_many :user_bikes, KoveRiders.UserBikes.UserBike

    timestamps(type: :utc_datetime)
  end

  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, KoveRiders.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def google_registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :google_id])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, KoveRiders.Repo)
    |> unique_constraint(:email)
    |> unique_constraint(:google_id)
    |> put_change(:confirmed_at, DateTime.utc_now(:second))
  end

  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  def valid_password?(%KoveRiders.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  def handle_changes_remaining(%__MODULE__{handle_change_count: count}) do
    max(@max_handle_changes - count, 0)
  end

  def handle_locked?(%__MODULE__{handle_change_count: count}), do: count >= @max_handle_changes

  def handle_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:handle])
    |> validate_required([:handle])
    |> validate_format(:handle, ~r/^[a-z0-9_]+$/,
      message: "only lowercase letters, numbers, and underscores"
    )
    |> validate_length(:handle, min: 3, max: 30)
    |> validate_handle_not_reserved()
    |> then(fn cs ->
      if Keyword.get(opts, :validate_unique, true) do
        cs
        |> unsafe_validate_unique(:handle, KoveRiders.Repo)
        |> unique_constraint(:handle)
      else
        cs
      end
    end)
  end

  defp validate_handle_not_reserved(changeset) do
    case get_change(changeset, :handle) do
      nil ->
        changeset

      handle ->
        if handle in @reserved_handles do
          add_error(changeset, :handle, "is reserved")
        else
          changeset
        end
    end
  end

  def handle_from_email(email) when is_binary(email) do
    email
    |> String.split("@")
    |> List.first("")
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.replace(~r/_+/, "_")
    |> String.trim("_")
    |> String.slice(0, 20)
  end
end
