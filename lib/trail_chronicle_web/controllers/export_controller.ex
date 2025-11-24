defmodule TrailChronicleWeb.ExportController do
  use TrailChronicleWeb, :controller

  alias TrailChronicle.Exports

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
end
