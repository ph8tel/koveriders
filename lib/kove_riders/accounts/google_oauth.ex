defmodule KoveRiders.Accounts.GoogleOAuth do
  @default_auth_base "https://accounts.google.com"
  @default_api_base "https://oauth2.googleapis.com"
  @default_userinfo_base "https://www.googleapis.com"

  def authorize_url(state) do
    params = %{
      client_id: client_id(),
      redirect_uri: redirect_uri(),
      response_type: "code",
      scope: "openid email profile",
      access_type: "online",
      state: state
    }

    "#{auth_url()}?#{URI.encode_query(params)}"
  end

  def exchange_code_for_token(code) do
    body = %{
      client_id: client_id(),
      client_secret: client_secret(),
      code: code,
      grant_type: "authorization_code",
      redirect_uri: redirect_uri()
    }

    case Req.post(token_url(), form: body) do
      {:ok, %{status: 200, body: body}} -> {:ok, body["access_token"]}
      {:ok, %{body: body}} -> {:error, "Token exchange failed: #{inspect(body)}"}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_user_info(access_token) do
    case Req.get(userinfo_url(), headers: [{"authorization", "Bearer #{access_token}"}]) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, %{email: body["email"], google_id: body["sub"], name: body["name"]}}

      {:ok, %{body: body}} ->
        {:error, "User info fetch failed: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def configured? do
    config = Application.get_env(:kove_riders, :google_oauth, [])

    not is_nil(config[:client_id]) and not is_nil(config[:client_secret]) and
      not is_nil(config[:redirect_uri])
  end

  defp auth_url do
    case Application.get_env(:kove_riders, :google_oauth_base_url) do
      nil -> "#{@default_auth_base}/o/oauth2/v2/auth"
      base -> "#{base}/o/oauth2/v2/auth"
    end
  end

  defp token_url do
    case Application.get_env(:kove_riders, :google_oauth_base_url) do
      nil -> "#{@default_api_base}/token"
      base -> "#{base}/oauth2/token"
    end
  end

  defp userinfo_url do
    case Application.get_env(:kove_riders, :google_oauth_base_url) do
      nil -> "#{@default_userinfo_base}/oauth2/v3/userinfo"
      base -> "#{base}/oauth2/v3/userinfo"
    end
  end

  defp client_id, do: Application.fetch_env!(:kove_riders, :google_oauth)[:client_id]
  defp client_secret, do: Application.fetch_env!(:kove_riders, :google_oauth)[:client_secret]
  defp redirect_uri, do: Application.fetch_env!(:kove_riders, :google_oauth)[:redirect_uri]
end
