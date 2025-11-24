defmodule TrailChronicleWeb.ExportController do
  use TrailChronicleWeb, :controller

  alias TrailChronicle.Exports
  alias TrailChronicle.Racing

  def csv(conn, _params) do
    athlete = conn.assigns.current_athlete
    csv_data = Exports.export_races_to_csv(athlete)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"my_races.csv\"")
    |> send_resp(200, csv_data)
  end

  def json(conn, _params) do
    athlete = conn.assigns.current_athlete
    json_data = Exports.export_races_to_json(athlete)

    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("content-disposition", "attachment; filename=\"my_races.json\"")
    |> send_resp(200, json_data)
  end

  def pdf(conn, %{"id" => id}) do
    athlete = conn.assigns.current_athlete
    race = Racing.get_race!(id)

    if race.athlete_id == athlete.id do
      case Exports.export_race_to_pdf(race) do
        {:ok, pdf_path} ->
          send_download(conn, {:file, pdf_path}, filename: "#{race.name}.pdf")

        {:error, message} ->
          conn
          |> put_flash(:error, message)
          |> redirect(to: ~p"/races/#{race.id}")
      end
    else
      conn
      |> put_flash(:error, "Not authorized")
      |> redirect(to: ~p"/races")
    end
  end
end
