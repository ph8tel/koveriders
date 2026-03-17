defmodule KoveRidersWeb.GoogleAuthController do
  use KoveRidersWeb, :controller

  alias KoveRiders.Accounts
  alias KoveRiders.Accounts.GoogleOAuth
  alias KoveRidersWeb.UserAuth

  def request(conn, _params) do
    state = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)

    conn
    |> put_session(:oauth_state, state)
    |> redirect(external: GoogleOAuth.authorize_url(state))
  end

  def callback(conn, %{"code" => code, "state" => state}) do
    stored_state = get_session(conn, :oauth_state)

    if state == stored_state do
      with {:ok, access_token} <- GoogleOAuth.exchange_code_for_token(code),
           {:ok, %{email: email, google_id: google_id}} <-
             GoogleOAuth.get_user_info(access_token),
           {:ok, user} <-
             Accounts.register_or_login_with_google(%{email: email, google_id: google_id}) do
        conn
        |> delete_session(:oauth_state)
        |> put_flash(:info, "Signed in with Google!")
        |> UserAuth.log_in_user(user)
      else
        {:error, reason} ->
          conn
          |> put_flash(:error, "Google sign-in failed: #{inspect(reason)}")
          |> redirect(to: ~p"/users/log-in")
      end
    else
      conn
      |> put_flash(:error, "OAuth state mismatch. Please try again.")
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def callback(conn, %{"code" => code}) do
    # fallback when no state param (e.g. during dev/test)
    with {:ok, access_token} <- GoogleOAuth.exchange_code_for_token(code),
         {:ok, %{email: email, google_id: google_id}} <- GoogleOAuth.get_user_info(access_token),
         {:ok, user} <-
           Accounts.register_or_login_with_google(%{email: email, google_id: google_id}) do
      conn
      |> put_flash(:info, "Signed in with Google!")
      |> UserAuth.log_in_user(user)
    else
      {:error, reason} ->
        conn
        |> put_flash(:error, "Google sign-in failed: #{inspect(reason)}")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def callback(conn, %{"error" => error}) do
    conn
    |> put_flash(:error, "Google sign-in was cancelled: #{error}")
    |> redirect(to: ~p"/users/log-in")
  end
end
