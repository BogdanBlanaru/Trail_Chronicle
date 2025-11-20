defmodule TrailChronicleWeb.PageController do
  use TrailChronicleWeb, :controller

  def home(conn, _params) do
    # Redirect to dashboard if authenticated, otherwise show landing
    if conn.assigns[:current_athlete] do
      redirect(conn, to: ~p"/dashboard")
    else
      render(conn, :home, layout: false)
    end
  end
end
