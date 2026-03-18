defmodule KoveRiders.Storage.Local do
  @moduledoc """
  Local filesystem storage adapter for testing and local development.
  Copies files to `System.tmp_dir!/0`/uploads/, returns relative paths.
  """
  @behaviour KoveRiders.Storage

  @impl true
  def upload_file(file_path, object_key, _content_type) do
    dest_dir = Path.join([System.tmp_dir!(), "uploads", Path.dirname(object_key)])
    File.mkdir_p!(dest_dir)
    dest_path = Path.join([System.tmp_dir!(), "uploads", object_key])
    File.copy!(file_path, dest_path)
    {:ok, public_url(object_key)}
  end

  @impl true
  def delete(object_key) do
    path = Path.join([System.tmp_dir!(), "uploads", object_key])
    File.rm(path)
    :ok
  end

  @impl true
  def public_url(object_key) do
    "/uploads/#{object_key}"
  end
end
