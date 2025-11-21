defmodule TrailChronicle.AI.Coach do
  @moduledoc """
  A smarter AI Coach that considers weather, terrain, and gear.
  Returns structured data (Map) instead of raw HTML.
  """

  alias TrailChronicle.Racing.Race

  def generate_analysis(%Race{} = race) do
    # Simulate "Thinking"
    Process.sleep(1500)

    dist = Decimal.to_float(race.distance_km || Decimal.new(0))
    gain = race.elevation_gain_m || 0
    temp = race.temperature_celsius || 15
    weather = String.downcase(race.weather_conditions || "clear")
    difficulty = race.terrain_difficulty || 1

    # 1. Weather Analysis
    weather_advice =
      cond do
        temp > 25 ->
          "⚠️ High Heat Alert. Pre-hydrate with electrolytes 24h before. Carry 500ml extra water."

        temp < 5 ->
          "🥶 Cold Conditions. Start with layers. Extremities (gloves/buff) are crucial for the first 5km."

        String.contains?(weather, "rain") ->
          "🌧️ Wet Course. Mud expected. Lube anti-chafe areas generously. Traction will be compromised."

        true ->
          "☀️ Optimal running conditions. Focus on cooling during high-exertion climbs."
      end

    # 2. Terrain & Shoe Analysis
    shoe_advice =
      if race.shoe do
        shoe_limit = race.shoe.distance_limit_km
        current_dist = Decimal.to_float(race.shoe.current_distance_km)
        life_left = current_dist / shoe_limit * 100

        cond do
          life_left > 90 ->
            "⚠️ Your #{race.shoe.model}s are near retirement. Check outsole grip before race day."

          difficulty >= 4 and String.contains?(String.downcase(race.shoe.brand), "hoka") and
              !String.contains?(String.downcase(race.shoe.model), "speedgoat") ->
            "Note: Your #{race.shoe.model}s might struggle on technical sections (Diff #{difficulty}). Take descents carefully."

          true ->
            "✅ Gear Check: The #{race.shoe.model} is a solid choice for this terrain."
        end
      else
        "No shoe data. Ensure you wear trail-specific shoes with 4mm+ lugs."
      end

    # 3. Pacing Strategy
    pacing =
      cond do
        difficulty >= 4 ->
          "Technical Course: Ignore your watch pace. Run by effort (RPE). Power hike all climbs >10% grade."

        dist > 40 ->
          "Ultra Mindset: The race starts at km 30. If you feel good at km 10, you are going too fast."

        true ->
          "Attack Mode: This is a runnable course. Push the flats and flow on the downhills."
      end

    # 4. Nutrition Plan
    nutrition =
      cond do
        dist < 15 ->
          "Minimal fueling needed. 1 gel at 45mins if effort is high. Hydrate to thirst."

        dist < 30 ->
          "Carb loading not required. 40-60g carbs/hr during race. 500ml fluid/hr."

        true ->
          "Critical: 60-90g carbs/hr. Start fueling at min 20. Salt tabs every hour if sweating heavily."
      end

    # Return a Map (which will be saved as JSON)
    %{
      "summary" => "Analysis for #{race.name} complete.",
      "weather_advice" => weather_advice,
      "shoe_advice" => shoe_advice,
      "pacing" => pacing,
      "nutrition" => nutrition,
      "score" => calculate_suffering_score(dist, gain, difficulty)
    }
  end

  defp calculate_suffering_score(dist, gain, diff) do
    # A fun 1-100 "Suffering Score"
    # 1.5 points per km
    base = dist * 1.5
    # 1 point per 100m
    vert = gain / 100
    # 5 points per difficulty level
    tech = diff * 5

    min(round(base + vert + tech), 100)
  end
end
