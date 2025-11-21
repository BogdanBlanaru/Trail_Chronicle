defmodule TrailChronicle.AI.Coach do
  @moduledoc """
  Simulates an AI Coach analyzing trail running data.
  In a real production app, the `generate_analysis/1` function
  would call the OpenAI API.
  """

  alias TrailChronicle.Racing.Race

  def generate_analysis(%Race{} = race) do
    # Simulate API network delay
    Process.sleep(1500)

    # 1. Extract Data Points
    dist = Decimal.to_float(race.distance_km || Decimal.new(0))
    gain = race.elevation_gain_m || 0
    # Calculate "Vert Ratio" (meters per km)
    ratio = if dist > 0, do: gain / dist, else: 0

    shoe_name = if race.shoe, do: "#{race.shoe.brand} #{race.shoe.model}", else: "standard shoes"

    # 2. "AI" Logic (Heuristics to mimic LLM responses)
    difficulty_text =
      cond do
        ratio > 50 -> "This is a vertical wall. Power hiking will be crucial."
        ratio > 30 -> "Significant climbing involved. Manage your heart rate on ascents."
        true -> "A runnable course. Focus on turnover and speed."
      end

    pacing_advice =
      cond do
        dist > 42 -> "Start extremely conservative. The race doesn't begin until km 30."
        dist > 20 -> "Hold back in the first 5k. Don't burn matches on the first climb."
        true -> "Threshold effort. Push the downhills."
      end

    # 3. Construct the "Response"
    # We return HTML-safe string for the frontend
    """
    <div class="space-y-4">
      <div class="p-4 bg-indigo-50 rounded-xl border border-indigo-100">
        <h4 class="font-bold text-indigo-900 flex items-center gap-2">
          🧠 Coach's Executive Summary
        </h4>
        <p class="text-indigo-800 text-sm mt-1">
          Analyzing <strong>#{race.name}</strong>: A #{dist}km effort with #{gain}m of vertical gain.
          #{difficulty_text}
        </p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <h5 class="font-bold text-slate-900 mb-2">⚡ Pacing Strategy</h5>
          <ul class="list-disc list-inside text-sm text-slate-600 space-y-1">
            <li>#{pacing_advice}</li>
            <li>Maintain steady cadence.</li>
            <li>Use the downhills to recover HR, but keep legs moving.</li>
          </ul>
        </div>
        <div>
          <h5 class="font-bold text-slate-900 mb-2">⛽ Nutrition Plan</h5>
          <ul class="list-disc list-inside text-sm text-slate-600 space-y-1">
            <li>Aim for 60-90g carbs/hour.</li>
            <li>Hydration: 500ml/hour minimum.</li>
            <li>Take a gel 15 mins before the start.</li>
          </ul>
        </div>
      </div>

      <div class="mt-4 pt-4 border-t border-slate-100">
        <h5 class="font-bold text-slate-900 mb-2">👟 Gear Check: #{shoe_name}</h5>
        <p class="text-sm text-slate-600">
          Good choice. Ensure laces are double-knotted. If wet conditions are expected,
          bring an extra pair of socks in your drop bag.
        </p>
      </div>
    </div>
    """
  end
end
