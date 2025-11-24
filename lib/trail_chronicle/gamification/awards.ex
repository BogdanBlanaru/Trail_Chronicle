defmodule TrailChronicle.Gamification.Awards do
  @moduledoc """
  Analyzes athlete history to award badges.
  """
  alias TrailChronicle.Racing

  def calculate_badges(athlete) do
    races = Racing.list_completed_races(athlete)
    stats = Racing.get_race_stats(athlete)

    [
      # Distance Milestones
      check_ultra_club(races),
      check_marathon_master(races),
      check_half_hero(races),

      # Vertical Milestones
      check_vertical_limit(stats),
      check_mountain_goat(races),
      check_sky_runner(races),

      # Consistency & Travel
      check_globe_trotter(races),
      check_winter_warrior(races),
      check_consistency_king(races),

      # Performance
      check_speed_demon(races),
      check_podium_finisher(races),

      # Fun / Unique
      check_mud_runner(races),
      check_night_owl(races)
    ]
  end

  defp check_ultra_club(races) do
    count = Enum.count(races, fn r -> r.race_type == "ultra" end)
    earned = count > 0

    %{
      id: :ultra_club,
      title: "Ultra Club",
      description: "Completed a race longer than 42km. Welcome to the pain cave.",
      icon: "⚡",
      color: "bg-purple-100 text-purple-700 border-purple-200",
      earned: earned,
      progress: if(earned, do: 100, else: 0)
    }
  end

  defp check_marathon_master(races) do
    count = Enum.count(races, fn r -> r.race_type in ["marathon", "ultra"] end)
    target = 5

    %{
      id: :marathon_master,
      title: "Endurance Master",
      description: "Completed 5 Marathons or Ultras. You don't know when to stop.",
      icon: "🏅",
      color: "bg-yellow-100 text-yellow-700 border-yellow-200",
      earned: count >= target,
      progress: min(round(count / target * 100), 100)
    }
  end

  defp check_half_hero(races) do
    count = Enum.count(races, fn r -> r.race_type == "half_marathon" end)
    target = 10

    %{
      id: :half_hero,
      title: "Half Hero",
      description: "Completed 10 Half Marathons. The perfect distance?",
      icon: "🏃",
      color: "bg-indigo-100 text-indigo-700 border-indigo-200",
      earned: count >= target,
      progress: min(round(count / target * 100), 100)
    }
  end

  defp check_vertical_limit(stats) do
    # 8848m is Everest height
    total_gain = stats.total_elevation_gain_m || 0
    target = 8848
    earned = total_gain >= target

    %{
      id: :everest,
      title: "Everest Equivalent",
      description: "Accumulated 8,848m of elevation gain. You've climbed the world.",
      icon: "🏔️",
      color: "bg-slate-100 text-slate-700 border-slate-200",
      earned: earned,
      progress: min(round(total_gain / target * 100), 100)
    }
  end

  defp check_mountain_goat(races) do
    # Single race with > 2000m gain
    earned = Enum.any?(races, fn r -> (r.elevation_gain_m || 0) > 2000 end)

    %{
      id: :mountain_goat,
      title: "Mountain Goat",
      description: "Climbed over 2,000m in a single race. Your quads hate you.",
      icon: "🐐",
      color: "bg-emerald-100 text-emerald-700 border-emerald-200",
      earned: earned
    }
  end

  defp check_sky_runner(races) do
    # Race with high vert ratio (> 50m/km)
    earned =
      Enum.any?(races, fn r ->
        dist = Decimal.to_float(r.distance_km || Decimal.new(1))
        gain = r.elevation_gain_m || 0
        gain / dist > 50
      end)

    %{
      id: :sky_runner,
      title: "Sky Runner",
      description: "Competed in a vertical race (>50m/km). Steep implies fun.",
      icon: "☁️",
      color: "bg-sky-100 text-sky-700 border-sky-200",
      earned: earned
    }
  end

  defp check_globe_trotter(races) do
    countries =
      races
      |> Enum.map(& &1.country)
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)
      |> length()

    target = 3

    %{
      id: :globe_trotter,
      title: "Globe Trotter",
      description: "Raced in 3 different countries. Running needs no translation.",
      icon: "🌍",
      color: "bg-blue-100 text-blue-700 border-blue-200",
      earned: countries >= target,
      progress: min(round(countries / target * 100), 100)
    }
  end

  defp check_speed_demon(races) do
    # Half marathon under 1h 45m (6300s) OR 10k under 45m (2700s)
    earned =
      Enum.any?(races, fn r ->
        ((r.race_type == "half_marathon" and r.finish_time_seconds) &&
           r.finish_time_seconds < 6300) or
          ((r.race_type == "10k" and r.finish_time_seconds) && r.finish_time_seconds < 2700)
      end)

    %{
      id: :speed_demon,
      title: "Speed Demon",
      description: "Sub 1:45 Half or Sub 45min 10k. Fast feet.",
      icon: "🔥",
      color: "bg-orange-100 text-orange-700 border-orange-200",
      earned: earned
    }
  end

  defp check_winter_warrior(races) do
    earned = Enum.any?(races, fn r -> r.race_date.month in [1, 2, 12] end)

    %{
      id: :winter_warrior,
      title: "Winter Warrior",
      description: "Completed a race in Dec, Jan, or Feb. No off-season.",
      icon: "❄️",
      color: "bg-cyan-100 text-cyan-700 border-cyan-200",
      earned: earned
    }
  end

  defp check_consistency_king(races) do
    # Simplified logic: Just check if total races >= 12
    count = length(races)
    target = 12

    %{
      id: :consistency,
      title: "Consistency King",
      description: "Completed 12 races total. Showing up is 90% of the battle.",
      icon: "👑",
      color: "bg-fuchsia-100 text-fuchsia-700 border-fuchsia-200",
      earned: count >= target,
      progress: min(round(count / target * 100), 100)
    }
  end

  defp check_podium_finisher(races) do
    # FIX: Safety check for nil values before comparison
    earned =
      Enum.any?(races, fn r ->
        (r.overall_position != nil and r.overall_position <= 3) or
          (r.category_position != nil and r.category_position <= 3)
      end)

    %{
      id: :podium,
      title: "Podium Finisher",
      description: "Top 3 finish in Overall or Category.",
      icon: "🏆",
      color: "bg-amber-100 text-amber-700 border-amber-200",
      earned: earned
    }
  end

  defp check_mud_runner(races) do
    # Check if any race report mentions "mud" or "rain"
    earned =
      Enum.any?(races, fn r ->
        text = String.downcase(r.race_report || "")
        String.contains?(text, "mud") or String.contains?(text, "rain")
      end)

    %{
      id: :mud_runner,
      title: "Mud Runner",
      description: "Survived a wet and muddy race.",
      icon: "🐷",
      color: "bg-stone-100 text-stone-700 border-stone-200",
      earned: earned
    }
  end

  defp check_night_owl(races) do
    # Check if race name contains "Night"
    earned =
      Enum.any?(races, fn r ->
        String.contains?(String.downcase(r.name || ""), "night")
      end)

    %{
      id: :night_owl,
      title: "Night Owl",
      description: "Completed a Night Race. Headlamp required.",
      icon: "🦉",
      # Dark theme badge
      color: "bg-indigo-900 text-indigo-100 border-indigo-800",
      earned: earned
    }
  end
end
