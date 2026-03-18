defmodule KoveRiders.Storage do
  @moduledoc """
  Facade over pluggable storage adapters.
  Configure the adapter via `config :kove_riders, :storage_adapter, MyAdapter`.
  Defaults to `KoveRiders.Storage.R2` in production.
  """

  @callback upload_file(String.t(), String.t(), String.t()) ::
              {:ok, String.t()} | {:error, String.t()}
  @callback delete(String.t()) :: :ok
  @callback public_url(String.t()) :: String.t()

  defp adapter do
    Application.get_env(:kove_riders, :storage_adapter, KoveRiders.Storage.R2)
  end

  def upload_file(file_path, object_key, content_type \\ "image/jpeg") do
    adapter().upload_file(file_path, object_key, content_type)
  end

  def delete(object_key), do: adapter().delete(object_key)

  def public_url(object_key), do: adapter().public_url(object_key)

  def generate_key(original_filename) do
    ext = original_filename |> Path.extname() |> String.downcase()
    uuid = Ecto.UUID.generate()
    "bike-photos/#{uuid}#{ext}"
  end

  def enabled?, do: adapter() == KoveRiders.Storage.R2
end
