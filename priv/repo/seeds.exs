alias TrailChronicle.{Repo, Accounts, Racing}

IO.puts("\n🌱 Starting seed data generation...\n")

# Clear existing data
IO.puts("🗑️  Clearing existing races...")
Repo.delete_all(Racing.Race)

IO.puts("🗑️  Clearing existing athletes...")
Repo.delete_all(Accounts.Athlete)

# Create the main athlete (Bogdan)
IO.puts("👤 Creating athlete: Bogdan Marinescu...")

# Step 1: Register (Basic Auth) - Password must be > 12 chars
{:ok, bogdan} =
  Accounts.register_athlete(%{
    "email" => "bogdan@example.com",
    "password" => "SecretPassword123!",
    "first_name" => "Bogdan",
    "last_name" => "Marinescu",
    "preferred_language" => "ro"
  })

# Step 2: Update Profile (Details)
{:ok, bogdan} =
  Accounts.update_athlete_profile(bogdan, %{
    "bio" =>
      "Trail runner from Romania passionate about mountain races and ultra marathons. Love pushing my limits in the mountains!",
    "date_of_birth" => "1995-06-15",
    "gender" => "M",
    "country" => "Romania",
    "city" => "Brașov",
    "height_cm" => 180,
    "weight_kg" => 75,
    "running_since_year" => 2018,
    "favorite_distance" => "ultra",
    "max_heart_rate" => 190,
    "resting_heart_rate" => 48,
    "preferred_unit_system" => "metric",
    "timezone" => "Europe/Bucharest"
  })

IO.puts("✅ Athlete created: #{bogdan.email}\n")

# Sample races data
races_data = [
  # Completed races - 2024
  %{
    "name" => "Retezat Sky Race 2024",
    "race_date" => "2024-08-17",
    "race_type" => "ultra",
    "status" => "completed",
    "country" => "Romania",
    "city" => "Cârnița",
    "latitude" => 45.3566,
    "longitude" => 22.8899,
    "distance_km" => 42,
    "elevation_gain_m" => 3200,
    "elevation_loss_m" => 3200,
    "finish_time_seconds" => 28800,
    "overall_position" => 45,
    "total_participants" => 120,
    "surface_type" => "trail",
    "terrain_difficulty" => 5,
    "weather_conditions" => "Sunny, hot",
    "temperature_celsius" => 28,
    "race_report" =>
      "Amazing race through Retezat mountains! The climbs were brutal but the views were worth it. My legs were destroyed by the technical descents but I pushed through. The high altitude sections were challenging.",
    "highlights" =>
      "Summit of Peleaga peak at sunrise, crystal clear mountain lakes, amazing single tracks through alpine meadows, saw a chamois near the ridge",
    "difficulties" =>
      "Very steep climbs in the middle section, some snow patches near the ridges, ran out of water between aid stations",
    "gear_used" => "Salomon Speedcross 5, Black Diamond poles, Salomon vest, Maurten gels"
  },
  %{
    "name" => "București Marathon 2024",
    "race_date" => "2024-10-13",
    "race_type" => "marathon",
    "status" => "completed",
    "country" => "Romania",
    "city" => "București",
    "distance_km" => 42.195,
    "elevation_gain_m" => 150,
    "finish_time_seconds" => 14400,
    "overall_position" => 234,
    "total_participants" => 3500,
    "surface_type" => "asphalt",
    "terrain_difficulty" => 1,
    "weather_conditions" => "Cloudy, perfect running weather",
    "temperature_celsius" => 15,
    "race_report" =>
      "My first road marathon! Much faster than trail races. The flat course helped me maintain a steady pace throughout. Great crowd support in the city center.",
    "highlights" =>
      "Running through the city center with huge crowd support, personal best time on road, perfect weather conditions",
    "difficulties" =>
      "Hip flexors started hurting around km 35, not used to running on asphalt for so long",
    "gear_used" => "Nike Vaporfly, Nathan hydration belt, energy gels every 5km"
  },
  %{
    "name" => "Piatra Craiului Marathon 2024",
    "race_date" => "2024-07-06",
    "race_type" => "trail",
    "status" => "completed",
    "country" => "Romania",
    "city" => "Zărnești",
    "latitude" => 45.5697,
    "longitude" => 25.3336,
    "distance_km" => 42,
    "elevation_gain_m" => 2800,
    "elevation_loss_m" => 2800,
    "finish_time_seconds" => 25200,
    "overall_position" => 28,
    "total_participants" => 85,
    "surface_type" => "trail",
    "terrain_difficulty" => 4,
    "weather_conditions" => "Partly cloudy, ideal",
    "temperature_celsius" => 22,
    "race_report" =>
      "Technical and challenging course through Piatra Craiului massif. The ridge sections were absolutely spectacular. Some scrambling required which slowed me down but was fun!",
    "highlights" =>
      "Running the ridge with 360-degree views, wild flowers everywhere, supportive local crowd at aid stations",
    "difficulties" =>
      "Technical rocky sections required careful foot placement, some exposed ridge sections with wind",
    "gear_used" => "La Sportiva Bushido II, Black Diamond poles, Ultimate Direction vest"
  },
  %{
    "name" => "Semimaraton Brașov 2024",
    "race_date" => "2024-05-19",
    "race_type" => "half_marathon",
    "status" => "completed",
    "country" => "Romania",
    "city" => "Brașov",
    "distance_km" => 21.1,
    "elevation_gain_m" => 180,
    "finish_time_seconds" => 6900,
    "overall_position" => 87,
    "total_participants" => 1200,
    "surface_type" => "asphalt",
    "terrain_difficulty" => 1,
    "weather_conditions" => "Light rain",
    "temperature_celsius" => 12,
    "race_report" =>
      "Local race in my hometown! Great atmosphere, ran with some friends. The rain made it a bit challenging but also kept us cool. Finished strong.",
    "highlights" =>
      "Running past familiar landmarks, friends and family cheering, good time despite the rain",
    "difficulties" => "Slippery conditions from rain, had to be careful on turns",
    "gear_used" => "Hoka Clifton 8, light rain jacket"
  },
  # Upcoming races - 2026
  %{
    "name" => "Făgăraș Ultra 2026",
    "race_date" => "2026-08-15",
    "race_type" => "ultra",
    "status" => "upcoming",
    "country" => "Romania",
    "city" => "Victoria",
    "latitude" => 45.7167,
    "longitude" => 24.7167,
    "distance_km" => 80,
    "elevation_gain_m" => 5000,
    "surface_type" => "trail",
    "terrain_difficulty" => 5,
    "official_website" => "https://fagaras-ultra.ro",
    "cost_eur" => 250,
    "registration_deadline" => "2026-07-01",
    "is_registered" => true
  },
  %{
    "name" => "UTMB Mont-Blanc 2026",
    "race_date" => "2026-08-28",
    "race_type" => "ultra",
    "status" => "upcoming",
    "country" => "France",
    "city" => "Chamonix",
    "latitude" => 45.9237,
    "longitude" => 6.8694,
    "distance_km" => 171,
    "elevation_gain_m" => 10000,
    "surface_type" => "trail",
    "terrain_difficulty" => 5,
    "official_website" => "https://utmb.world",
    "cost_eur" => 380,
    "registration_deadline" => "2026-07-15",
    "is_registered" => true
  },
  %{
    "name" => "Bucegi Marathon 2026",
    "race_date" => "2026-07-12",
    "race_type" => "marathon",
    "status" => "upcoming",
    "country" => "Romania",
    "city" => "Bușteni",
    "latitude" => 45.4166,
    "longitude" => 25.5397,
    "distance_km" => 42.195,
    "elevation_gain_m" => 2100,
    "surface_type" => "trail",
    "terrain_difficulty" => 4,
    "official_website" => "https://bucegi-marathon.ro",
    "cost_eur" => 150,
    "registration_deadline" => "2026-06-30",
    "is_registered" => true
  }
]

# Insert races
IO.puts("🏃 Creating #{length(races_data)} races...\n")

Enum.each(races_data, fn race_data ->
  case Racing.create_race(bogdan, race_data) do
    {:ok, race} ->
      status_emoji =
        case race.status do
          "completed" -> "✅"
          "upcoming" -> "📅"
          _ -> "⏳"
        end

      IO.puts("#{status_emoji} #{race.name} - #{race.race_date}")

    {:error, changeset} ->
      IO.puts("❌ Failed to create race: #{race_data["name"]}")
      IO.inspect(changeset.errors)
  end
end)

# Print summary
stats = Racing.get_race_stats(bogdan)
all_races = Racing.list_races(bogdan)

IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("🎉 SEED DATA GENERATION COMPLETE!")
IO.puts(String.duplicate("=", 50))
IO.puts("\n📊 Summary:")
IO.puts("   • Total races: #{length(all_races)}")
IO.puts("   • Completed: #{stats.total_races}")
IO.puts("   • Total distance: #{stats.total_distance_km} km")
IO.puts("   • Total elevation: #{stats.total_elevation_gain_m} m")
IO.puts("\n👤 Athlete Creds:")
IO.puts("   • Email: bogdan@example.com")
IO.puts("   • Password: SecretPassword123!")
IO.puts("\n👉 IMPORTANT: Please Log Out and Log In again to see the new data.")
IO.puts(String.duplicate("=", 50) <> "\n")
