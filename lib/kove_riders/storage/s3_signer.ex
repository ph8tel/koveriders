defmodule KoveRiders.Storage.S3Signer do
  def sign_headers(method, url, headers, body, config) do
    access_key_id = Keyword.fetch!(config, :access_key_id)
    secret_access_key = Keyword.fetch!(config, :secret_access_key)
    region = Keyword.get(config, :region, "auto")

    uri = URI.parse(url)
    now = DateTime.utc_now()
    date = Calendar.strftime(now, "%Y%m%d")
    datetime = Calendar.strftime(now, "%Y%m%dT%H%M%SZ")
    payload_hash = sha256_hex(body)

    all_headers =
      [
        {"host", uri.host},
        {"x-amz-content-sha256", payload_hash},
        {"x-amz-date", datetime} | headers
      ]
      |> Enum.uniq_by(&elem(&1, 0))
      |> Enum.sort_by(&elem(&1, 0))

    signed_header_names = all_headers |> Enum.map(&elem(&1, 0)) |> Enum.join(";")

    canonical_headers =
      all_headers |> Enum.map(fn {k, v} -> "#{k}:#{String.trim(v)}" end) |> Enum.join("\n")

    canonical_request =
      Enum.join(
        [
          method |> to_string() |> String.upcase(),
          uri.path || "/",
          uri.query || "",
          canonical_headers <> "\n",
          signed_header_names,
          payload_hash
        ],
        "\n"
      )

    scope = "#{date}/#{region}/s3/aws4_request"

    string_to_sign =
      Enum.join(["AWS4-HMAC-SHA256", datetime, scope, sha256_hex(canonical_request)], "\n")

    signing_key =
      hmac_sha256("AWS4" <> secret_access_key, date)
      |> hmac_sha256(region)
      |> hmac_sha256("s3")
      |> hmac_sha256("aws4_request")

    signature = signing_key |> hmac_sha256(string_to_sign) |> Base.encode16(case: :lower)

    authorization =
      "AWS4-HMAC-SHA256 Credential=#{access_key_id}/#{scope}, " <>
        "SignedHeaders=#{signed_header_names}, Signature=#{signature}"

    all_headers
    |> Enum.reject(fn {k, _} -> k == "host" end)
    |> Enum.concat([{"authorization", authorization}])
  end

  defp sha256_hex(data), do: :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  defp hmac_sha256(key, data), do: :crypto.mac(:hmac, :sha256, key, data)
end
