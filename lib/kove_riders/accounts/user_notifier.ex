defmodule KoveRiders.Accounts.UserNotifier do
  import Swoosh.Email
  alias KoveRiders.Mailer
  alias KoveRiders.Accounts.User

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"KoveRiders", "noreply@koveriders.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email), do: {:ok, email}
  end

  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in to KoveRiders", """

    ==============================

    Hi #{user.email},

    Log in to your KoveRiders account:

    #{url}

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirm your KoveRiders account", """

    ==============================

    Hi #{user.email},

    Confirm your account:

    #{url}

    ==============================
    """)
  end
end
