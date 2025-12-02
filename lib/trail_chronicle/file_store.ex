defmodule TrailChronicle.FileStore do
  @moduledoc """
  Handles file uploads to local storage.
  Adapted for local development (skipping Cloudflare R2 logic for now).
  """

  def upload_photo(source_path, filename) do
    upload_to_local(source_path, filename)
  end

  def delete_photo(image_url) do
    # Remove the leading slash for Path.join to work correctly with relative paths
    clean_path = String.replace_leading(image_url, "/", "")
    path = Path.join(["priv", "static", clean_path])
    File.rm(path)
  end

  defp upload_to_local(source_path, filename) do
    upload_dir = Path.join(["priv", "static", "uploads"])
    File.mkdir_p!(upload_dir)
    dest = Path.join(upload_dir, filename)
    File.cp!(source_path, dest)
    {:ok, "/uploads/#{filename}"}
  end
end
