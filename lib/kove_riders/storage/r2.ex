defmodule KoveRiders.Storage.R2 do
  @moduledoc "Cloudflare R2 storage adapter."
  @behaviour KoveRiders.Storage

  require Logger

  alias KoveRiders.Storage.S3Signer

  @impl true
  def upload_file(file_path, object_key, content_type) do
    config = config()
    body = File.read!(file_path)
    url = endpoint_url(config, object_key)
    headers = S3Signer.sign_headers(:put, url, [{"content-type", content_type}], body, config)

    case Req.put(url, body: body, headers: headers) do
      {:ok, %{status: status}} when status in 200..299 ->
        {:ok, public_url(object_key)}

      {:ok, %{status: status, body: resp_body}} ->
        {:error, "R2 upload failed (#{status}): #{inspect(resp_body)}"}

      {:error, exception} ->
        {:error, "R2 upload error: #{Exception.message(exception)}"}
    end
  end

  @impl true
  def delete(object_key) do
    config = config()
    url = endpoint_url(config, object_key)
    headers = S3Signer.sign_headers(:delete, url, [], "", config)

    case Req.delete(url, headers: headers) do
      {:ok, %{status: status}} when status in 200..299 -> :ok
      {:ok, %{status: 404}} -> :ok
      _ -> :ok
    end
  end

  @impl true
  def public_url(object_key) do
    "#{config()[:public_url]}/#{object_key}"
  end

  defp endpoint_url(config, object_key),
    do: "#{config[:endpoint]}/#{config[:bucket]}/#{object_key}"

  defp config, do: Application.get_env(:kove_riders, KoveRiders.Storage, [])
end
