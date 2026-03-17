defmodule KoveRiders.Storage do
  alias KoveRiders.Storage.S3Signer

  def upload_file(file_path, object_key, content_type \\ "image/jpeg") do
    config = config()
    require Logger

    if config[:enabled] do
      body = File.read!(file_path)
      url = endpoint_url(config, object_key)
      headers = S3Signer.sign_headers(:put, url, [{"content-type", content_type}], body, config)

      case Req.put(url, body: body, headers: headers) do
        {:ok, %{status: status}} when status in 200..299 ->
          {:ok, public_url(object_key, config)}

        {:ok, %{status: status, body: resp_body}} ->
          {:error, "R2 upload failed (#{status}): #{inspect(resp_body)}"}

        {:error, exception} ->
          {:error, "R2 upload error: #{Exception.message(exception)}"}
      end
    else
      Logger.warning("R2 storage disabled — returning placeholder for #{object_key}")
      {:ok, placeholder_url(object_key)}
    end
  end

  def delete(object_key) do
    config = config()

    if config[:enabled] do
      url = endpoint_url(config, object_key)
      headers = S3Signer.sign_headers(:delete, url, [], "", config)

      case Req.delete(url, headers: headers) do
        {:ok, %{status: status}} when status in 200..299 -> :ok
        {:ok, %{status: 404}} -> :ok
        _ -> :ok
      end
    else
      :ok
    end
  end

  def public_url(object_key, config \\ nil) do
    config = config || config()
    "#{config[:public_url]}/#{object_key}"
  end

  def generate_key(original_filename) do
    ext = original_filename |> Path.extname() |> String.downcase()
    uuid = Ecto.UUID.generate()
    "bike-photos/#{uuid}#{ext}"
  end

  def enabled?, do: config()[:enabled] == true

  defp endpoint_url(config, object_key),
    do: "#{config[:endpoint]}/#{config[:bucket]}/#{object_key}"

  defp placeholder_url(object_key), do: "/uploads/#{object_key}"
  defp config, do: Application.get_env(:kove_riders, __MODULE__, [])
end
