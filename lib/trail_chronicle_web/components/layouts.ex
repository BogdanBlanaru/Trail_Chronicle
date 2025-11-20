defmodule TrailChronicleWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.
  """

  use TrailChronicleWeb, :html

  embed_templates "layouts/*"

  @doc """
  Returns CSS classes for navigation links based on current path.
  """
  def nav_link_class(current_path, link_path) do
    base_classes =
      "group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors duration-200"

    if current_path == link_path do
      "#{base_classes} bg-blue-900 text-white"
    else
      "#{base_classes} text-blue-100 hover:bg-blue-700 hover:text-white"
    end
  end
end
