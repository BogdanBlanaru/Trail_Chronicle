defmodule TrailChronicle.Accounts.AthleteNotifier do
  import Swoosh.Email

  alias TrailChronicle.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Trail Chronicle", "noreply@trailchronicle.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(athlete, url) do
    deliver(athlete.email, "Confirmation instructions", """

    ==============================

    Hi #{athlete.first_name},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a athlete password.
  """
  def deliver_reset_password_instructions(athlete, url) do
    deliver(athlete.email, "Reset password instructions", """

    ==============================

    Hi #{athlete.first_name},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a athlete email.
  """
  def deliver_update_email_instructions(athlete, url) do
    deliver(athlete.email, "Update email instructions", """

    ==============================

    Hi #{athlete.first_name},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
