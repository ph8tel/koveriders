defmodule KoveRiders.Accounts.Scope do
  alias KoveRiders.Accounts.User
  defstruct user: nil

  def for_user(%User{} = user), do: %__MODULE__{user: user}
  def for_user(nil), do: nil
end
