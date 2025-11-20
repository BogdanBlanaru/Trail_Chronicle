defmodule TrailChronicleWeb.AthleteSessionController do
  use TrailChronicleWeb, :controller

  alias TrailChronicle.Accounts
  alias TrailChronicleWeb.AthleteAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:athlete_return_to, ~p"/athletes/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"athlete" => athlete_params}, info) do
    %{"email" => email, "password" => password} = athlete_params

    if athlete = Accounts.get_athlete_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> AthleteAuth.log_in_athlete(athlete, athlete_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/athletes/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> AthleteAuth.log_out_athlete()
  end
end
