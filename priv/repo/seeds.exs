# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TrailChronicle.Repo.insert!(%TrailChronicle.SomeSchema{})
#

alias TrailChronicle.{Repo, Accounts, Racing}

IO.puts("\n🌱 Starting seed data generation...\n")

# Clear existing data (optional - comment out if you want to keep existing data)
IO.puts("🗑️  Clearing existing races...")
Repo.delete_all(Racing.Race)

IO.puts("🗑️  Clearing existing athletes...")
Repo.delete_all(Accounts.Athlete)

# Create the main athlete (Bogdan)
IO.puts("👤 Creating athlete: Bogdan Marinescu...")

{:ok, bogdan} =
  Accounts.create_athlete(%{
    "email" => "bogdan@example.com",
    "password" => "Secret123",
    "first_name" => "Bogdan",
    "last_name" => "Marinescu",
    "bio" =>
      "Trail runner from Romania passionate about mountain races and ultra marathons. Love pushing my limits in the mountains!",
    "date_of_birth" => "1995-06-15",
    "gender" => "male",
    "country" => "Romania",
    "city" => "Brașov",
    "height_cm" => 180,
    "weight_kg" => 75,
    "running_since_year" => 2018,
    "favorite_distance" => "ultra",
    "max_heart_rate" => 190,
    "resting_heart_rate" => 48,
    "preferred_language" => "ro",
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
  %{
    "name" => "Transgrancanaria 2024",
    "race_date" => "2024-03-01",
    "race_type" => "ultra",
    "status" => "completed",
    "country" => "Spain",
    "city" => "Las Palmas",
    "latitude" => 27.9202,
    "longitude" => -15.5474,
    "distance_km" => 65,
    "elevation_gain_m" => 4200,
    "elevation_loss_m" => 4200,
    "finish_time_seconds" => 39600,
    "overall_position" => 156,
    "category_position" => 42,
    "total_participants" => 350,
    "surface_type" => "trail",
    "terrain_difficulty" => 5,
    "weather_conditions" => "Hot and humid",
    "temperature_celsius" => 26,
    "race_report" =>
      "First international race! Gran Canaria is absolutely stunning. The course was brutal - so many ups and downs. The heat and humidity were harder than expected. Struggled in the second half but finished!",
    "highlights" =>
      "Incredible volcanic landscapes, running above the clouds, meeting runners from all over Europe, amazing post-race party",
    "difficulties" =>
      "Heat and humidity caused cramping, navigation was tricky in some sections, language barrier at aid stations",
    "gear_used" => "Hoka Speedgoat 5, Salomon Sense Pro 10 vest, plenty of salt tabs"
  },

  # Completed races - 2023
  %{
    "name" => "Ultra-Trail Făgăraș 2023",
    "race_date" => "2023-08-25",
    "race_type" => "ultra",
    "status" => "completed",
    "country" => "Romania",
    "city" => "Victoria",
    "latitude" => 45.7167,
    "longitude" => 24.7167,
    "distance_km" => 80,
    "elevation_gain_m" => 5000,
    "elevation_loss_m" => 5000,
    "finish_time_seconds" => 46800,
    "overall_position" => 67,
    "total_participants" => 180,
    "surface_type" => "trail",
    "terrain_difficulty" => 5,
    "weather_conditions" => "Variable - sun, clouds, light rain",
    "temperature_celsius" => 15,
    "race_report" =>
      "My longest race to date! Făgăraș mountains are unforgiving but beautiful. Multiple 2500m+ peaks. Night section was magical but exhausting. This race pushed me to my absolute limits.",
    "highlights" =>
      "Sunset from Moldoveanu peak (highest in Romania), starry night running, camaraderie with other runners",
    "difficulties" =>
      "Extreme fatigue after 60km, hallucinations during night section, blisters on both feet",
    "gear_used" =>
      "Altra Lone Peak 6, headlamp with spare batteries, Black Diamond poles, compression socks"
  },
  %{
    "name" => "Bucovina Ultra Rocks 2023",
    "race_date" => "2023-06-17",
    "race_type" => "trail",
    "status" => "completed",
    "country" => "Romania",
    "city" => "Vatra Dornei",
    "distance_km" => 38,
    "elevation_gain_m" => 1800,
    "elevation_loss_m" => 1800,
    "finish_time_seconds" => 19800,
    "overall_position" => 41,
    "total_participants" => 95,
    "surface_type" => "trail",
    "terrain_difficulty" => 3,
    "weather_conditions" => "Sunny",
    "temperature_celsius" => 24,
    "race_report" =>
      "Beautiful race through Bucovina forests and meadows. More runnable than other mountain races. Good rhythm throughout. Loved the traditional Romanian food at aid stations!",
    "highlights" =>
      "Traditional Romanian hospitality at aid stations, running through pristine forests, painted monasteries views",
    "difficulties" =>
      "One steep technical descent was challenging, warm weather required extra hydration",
    "gear_used" => "Saucony Peregrine 12, Salomon soft flask, trail mix and energy bars"
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
  },
  %{
    "name" => "Transvulcania 2026",
    "race_date" => "2026-05-09",
    "race_type" => "ultra",
    "status" => "upcoming",
    "country" => "Spain",
    "city" => "Los Llanos de Aridane",
    "latitude" => 28.6574,
    "longitude" => -17.9177,
    "distance_km" => 73,
    "elevation_gain_m" => 4350,
    "surface_type" => "trail",
    "terrain_difficulty" => 5,
    "official_website" => "https://transvulcania.com",
    "cost_eur" => 195,
    "registration_deadline" => "2026-04-15",
    "is_registered" => false
  },
  %{
    "name" => "Lavaredo Ultra Trail 2026",
    "race_date" => "2026-06-26",
    "race_type" => "ultra",
    "status" => "upcoming",
    "country" => "Italy",
    "city" => "Cortina d'Ampezzo",
    "latitude" => 46.5369,
    "longitude" => 12.1357,
    "distance_km" => 120,
    "elevation_gain_m" => 5800,
    "surface_type" => "trail",
    "terrain_difficulty" => 5,
    "official_website" => "https://lavaredo-ultratrail.com",
    "cost_eur" => 320,
    "registration_deadline" => "2026-05-31",
    "is_registered" => false
  },
  %{
    "name" => "Semimaraton București 2026",
    "race_date" => "2026-04-19",
    "race_type" => "half_marathon",
    "status" => "upcoming",
    "country" => "Romania",
    "city" => "București",
    "distance_km" => 21.1,
    "elevation_gain_m" => 50,
    "surface_type" => "asphalt",
    "terrain_difficulty" => 1,
    "official_website" => "https://semimaratonbucuresti.ro",
    "cost_eur" => 80,
    "registration_deadline" => "2026-04-01",
    "is_registered" => true
  },
  %{
    "name" => "Retezat Sky Race 2026",
    "race_date" => "2026-08-22",
    "race_type" => "ultra",
    "status" => "upcoming",
    "country" => "Romania",
    "city" => "Cârnița",
    "latitude" => 45.3566,
    "longitude" => 22.8899,
    "distance_km" => 42,
    "elevation_gain_m" => 3200,
    "surface_type" => "trail",
    "terrain_difficulty" => 5,
    "official_website" => "https://retezat-sky-race.ro",
    "cost_eur" => 180,
    "registration_deadline" => "2026-08-01",
    "is_registered" => false
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
upcoming_races = Racing.list_upcoming_races(bogdan)

IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("🎉 SEED DATA GENERATION COMPLETE!")
IO.puts(String.duplicate("=", 50))
IO.puts("\n📊 Summary:")
IO.puts("   • Total races: #{length(all_races)}")
IO.puts("   • Completed: #{stats.total_races}")
IO.puts("   • Upcoming: #{length(upcoming_races)}")
IO.puts("   • Total distance: #{stats.total_distance_km} km")
IO.puts("   • Total elevation: #{stats.total_elevation_gain_m} m")
IO.puts("\n👤 Athlete:")
IO.puts("   • Email: #{bogdan.email}")
IO.puts("   • Password: Secret123")
IO.puts("\n✨ Visit http://localhost:4000 to see your data!")
IO.puts(String.duplicate("=", 50) <> "\n")
