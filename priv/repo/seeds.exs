alias TrailChronicle.{Repo, Accounts, Racing}
alias TrailChronicle.Racing.{Race, Shoe}

IO.puts("\n🌱 Starting seed data generation...\n")

# 1. Clear existing data
IO.puts("🗑️  Clearing existing races...")
Repo.delete_all(Race)
Repo.delete_all(Shoe)
IO.puts("🗑️  Clearing existing athletes...")
Repo.delete_all(Accounts.Athlete)

# 2. Create the main athlete
IO.puts("👤 Creating athlete: Bogdan Blanaru...")

{:ok, athlete} =
  Accounts.register_athlete(%{
    "email" => "bogdan.blanaru97@gmail.com",
    "password" => "H0YoUM7Lc5r2DwV.",
    "first_name" => "Bogdan",
    "last_name" => "Blanaru",
    "preferred_language" => "ro"
  })

# FIX: Truncate microseconds to match Ecto defaults
now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

athlete =
  athlete
  |> Ecto.Changeset.change(confirmed_at: now)
  |> Repo.update!()

{:ok, athlete} =
  Accounts.update_athlete_profile(athlete, %{
    "bio" =>
      "Trail runner passionate about pushing limits. Tracking my journey from evening runs to ultra marathons.",
    "gender" => "M",
    "country" => "Romania",
    "city" => "Brașov",
    "height_cm" => 180,
    "weight_kg" => 75,
    "running_since_year" => 2020,
    "favorite_distance" => "ultra",
    "preferred_unit_system" => "metric",
    "timezone" => "Europe/Bucharest"
  })

IO.puts("✅ Athlete created: #{athlete.email}\n")

# 3. Create The Shoe Garage
IO.puts("👟 Building the Shoe Garage...")

# Trail Shoe: Nnormal Tomir 2.0
tomir =
  Repo.insert!(%Shoe{
    athlete_id: athlete.id,
    brand: "Nnormal",
    model: "Tomir 2.0",
    nickname: "The Kilians",
    distance_limit_km: 900,
    is_retired: false,
    purchased_at: ~D[2025-04-01],
    inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
    updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
  })

# Road Shoe 1: Hoka Clifton 8
clifton8 =
  Repo.insert!(%Shoe{
    athlete_id: athlete.id,
    brand: "Hoka",
    model: "Clifton 8",
    nickname: "Daily Trainer (Old)",
    distance_limit_km: 800,
    is_retired: true,
    purchased_at: ~D[2024-01-01],
    inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
    updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
  })

# Road Shoe 2: Hoka Clifton 9
clifton9 =
  Repo.insert!(%Shoe{
    athlete_id: athlete.id,
    brand: "Hoka",
    model: "Clifton 9",
    nickname: "Daily Trainer (New)",
    distance_limit_km: 800,
    is_retired: false,
    purchased_at: ~D[2025-09-01],
    inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
    updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
  })

# 4. Define Helper Logic for Importing
classify_race = fn name, dist, elev ->
  name_lower = String.downcase(name)

  # Determine Type
  type =
    cond do
      dist >= 43.0 -> "ultra"
      dist >= 42.0 -> "marathon"
      dist >= 21.0 -> "half_marathon"
      String.contains?(name_lower, "cross") or String.contains?(name_lower, "cros") -> "10k"
      dist >= 9.5 and dist <= 10.5 -> "10k"
      dist >= 4.5 and dist <= 5.5 -> "5k"
      true -> "trail"
    end

  # Determine Surface
  climb_ratio = if dist > 0, do: elev / dist, else: 0

  surface =
    if climb_ratio > 20 or String.contains?(name_lower, "trail") or
         String.contains?(name_lower, "mountain") or String.contains?(name_lower, "ciucaș") or
         String.contains?(name_lower, "postăvaru"),
       do: "trail",
       else: "asphalt"

  # Determine Difficulty
  difficulty =
    cond do
      climb_ratio < 10 -> 1
      climb_ratio < 25 -> 2
      climb_ratio < 40 -> 3
      climb_ratio < 60 -> 4
      true -> 5
    end

  # Is it a "Real Race"?
  is_race =
    String.match?(name, ~r/(Marathon|Semimaraton|Trail|Race|Cros|X3|Festival|RunIasi|Up to)/i)

  final_type = if is_race, do: type, else: "other"

  {final_type, surface, difficulty, is_race}
end

# 5. The Data
raw_activities = [
  {"Evening Run", "2024-03-14", 4929, 11.56, 15, "Brașov"},
  {"Evening Run", "2024-03-17", 7035, 15.99, 29, "Brașov"},
  {"Evening Run", "2024-03-24", 4247, 11.11, 103, "Brașov"},
  {"Evening Run", "2024-03-25", 9429, 20.82, 50, "Brașov"},
  {"Afternoon Run", "2024-04-20", 7596, 16.98, 120, "Brașov"},
  {"Afternoon Run", "2024-04-21", 4902, 12.77, 235, "Brașov"},
  {"42 hours fasting run", "2024-04-23", 2773, 6.33, 9, "Brașov"},
  {"Evening Run", "2024-04-25", 3139, 8.56, 12, "Brașov"},
  {"Afternoon Run", "2024-05-01", 12843, 28.30, 121, "Brașov"},
  {"Evening Run", "2024-05-07", 3488, 10.00, 52, "Brașov"},
  {"Evening Run", "2024-05-09", 6766, 17.21, 87, "Brașov"},
  {"Evening Run", "2024-05-25", 2083, 4.01, 9, "Brașov"},
  {"Afternoon Run", "2024-05-31", 2515, 5.01, 65, "Brașov"},
  {"Brașov semimaraton", "2024-06-01", 16318, 23.68, 1089, "Brașov"},
  {"Evening Run", "2024-06-06", 4061, 11.08, 206, "Brașov"},
  {"Evening Run", "2024-06-08", 4179, 8.41, 95, "Brașov"},
  {"Evening Run", "2024-06-11", 2594, 6.81, 3, "Brașov"},
  {"Night Run", "2024-07-02", 6832, 16.62, 12, "Brașov"},
  {"Evening Run", "2024-07-08", 2159, 5.64, 5, "Brașov"},
  {"Night Run", "2024-07-13", 3758, 10.00, 3, "Brașov"},
  {"Bucovina Rumble Rocks", "2024-07-28", 11127, 18.80, 616, "Vatra Dornei"},
  {"Evening Run", "2024-08-13", 5765, 13.62, 6, "Brașov"},
  {"Evening Run", "2024-08-27", 3186, 6.39, 15, "Brașov"},
  {"Evening Run", "2024-08-28", 4107, 10.21, 16, "Brașov"},
  {"Evening Run", "2024-09-06", 2534, 3.76, 73, "Brașov"},
  {"Ciucaș X3 2024", "2024-09-08", 12392, 20.93, 1290, "Cheia"},
  {"Crosul Arenelor 2024", "2024-09-22", 3351, 10.09, 8, "București"},
  {"Bimbo race 5k", "2024-09-29", 1567, 4.57, 88, "Brașov"},
  {"Lunch Run", "2024-09-29", 3135, 8.28, 31, "Brașov"},
  {"Azuga Trail Run 2024", "2024-10-19", 10808, 21.11, 1199, "Azuga"},
  {"Evening Run", "2025-01-28", 6458, 15.59, 85, "Brașov"},
  {"Evening Run", "2025-04-14", 14143, 26.27, 258, "Brașov"},
  {"Evening Run", "2025-04-24", 4033, 10.34, 102, "Brașov"},
  {"Evening Run", "2025-04-25", 3374, 4.48, 7, "Brașov"},
  {"Semimaraton Iasi 2025", "2025-04-27", 7947, 21.41, 282, "Iași"},
  {"Evening Run", "2025-04-28", 3135, 5.08, 27, "Brașov"},
  {"Afternoon Run", "2025-05-01", 9126, 9.25, 126, "Brașov"},
  {"Afternoon Run", "2025-05-04", 6507, 10.10, 432, "Brașov"},
  {"Subcarpați Trail Run 2025", "2025-05-10", 11952, 23.93, 1008, "Câmpina"},
  {"Evening Run", "2025-05-14", 5592, 10.01, 662, "Brașov"},
  {"EcoRun Moieciu 2025", "2025-05-17", 6441, 13.92, 640, "Moieciu"},
  {"Evening Run", "2025-05-20", 9049, 18.29, 121, "Brașov"},
  {"Semimaraton Casa Bună Sânpetru 2025", "2025-05-24", 9881, 20.77, 901, "Sânpetru"},
  {"Brașov Marathon Semimaraton 2025", "2025-05-31", 10534, 22.23, 1111, "Brașov"},
  {"Evening Run", "2025-06-04", 3298, 7.25, 52, "Brașov"},
  {"Festivalul sporturilor Iași 11km 2025", "2025-06-07", 7661, 10.88, 360, "Iași"},
  {"Evening Run", "2025-06-12", 9849, 25.01, 283, "Brașov"},
  {"Morning Run", "2025-06-15", 1806, 3.48, 24, "Brașov"},
  {"Evening Run", "2025-06-24", 9668, 17.78, 950, "Brașov"},
  {"Carpathia trails 36km & 2000m 2025", "2025-07-05", 22154, 35.79, 2099, "Cheile Grădiștei"},
  {"Morning Run", "2025-07-06", 4632, 8.70, 536, "Brașov"},
  {"Evening Run", "2025-07-08", 5701, 15.20, 243, "Brașov"},
  {"Evening Run", "2025-07-18", 3620, 10.00, 72, "Brașov"},
  {"Up to Postăvaru Race 2025", "2025-07-20", 6016, 12.07, 796, "Brașov"},
  {"Morning Run", "2025-07-25", 6852, 4.80, 573, "Brașov"},
  {"Bucovina Ultra Rocks Radical 21km 2025", "2025-07-26", 11420, 21.51, 1166,
   "Câmpulung Moldovenesc"},
  {"Morning Run", "2025-08-17", 5766, 15.06, 95, "Brașov"},
  {"Lunch Run", "2025-08-23", 11196, 20.00, 1085, "Brașov"},
  {"Lunch Run", "2025-08-24", 5510, 6.48, 664, "Brașov"},
  {"Râșnov Medieval Run 2025", "2025-08-30", 12068, 24.82, 1047, "Râșnov"},
  {"Evening Run", "2025-09-04", 6984, 13.39, 194, "Brașov"},
  {"Ciucaș X3 21 km 2025", "2025-09-07", 11279, 21.09, 1283, "Cheia"},
  {"Evening Run", "2025-09-10", 6506, 15.28, 113, "Brașov"},
  {"Sighișoara 10k 2025", "2025-09-14", 3094, 9.38, 161, "Sighișoara"},
  {"Omu Marathon 2025", "2025-09-20", 32092, 41.75, 3171, "Bușteni"},
  {"Evening Run", "2025-09-25", 3884, 10.14, 48, "Brașov"},
  {"Evening Run", "2025-09-29", 3956, 10.31, 39, "Brașov"},
  {"Brașov Running Festival - TrailToRoad 12k", "2025-10-04", 4277, 11.21, 272, "Brașov"},
  {"Brașov Running Festival 10k 2025", "2025-10-05", 3112, 10.04, 17, "Brașov"},
  {"Bucharest Marathon 2025", "2025-10-12", 15784, 42.30, 136, "București"},
  {"Azuga Trail Race 2025", "2025-10-18", 10489, 21.15, 1198, "Azuga"},
  {"Evening Run", "2025-10-23", 4150, 12.66, 165, "Brașov"},
  {"Brașov Marathon - Night Challenge 2025", "2025-10-25", 2982, 7.13, 369, "Brașov"},
  {"RunIasi 2025", "2025-10-26", 5204, 10.08, 169, "Iași"},
  {"Evening Run", "2025-10-30", 4241, 11.05, 33, "Brașov"},
  {"Băneasa Forest Run 21k 2025", "2025-11-02", 7449, 21.29, 42, "București"},
  {"Măgurele Running Trails 22k 2025", "2025-11-09", 7459, 21.88, 42, "Măgurele"},
  {"Crosul 15 noiembrie 2025", "2025-11-15", 1768, 5.03, 16, "Brașov"},
  {"Morning Run", "2025-11-16", 6229, 15.20, 213, "Brașov"}
]

IO.puts("🏃 Importing #{length(raw_activities)} activities...")

Enum.each(raw_activities, fn {name, date_str, time, dist, elev, city} ->
  {type, surface, difficulty, _is_race} = classify_race.(name, dist, elev)

  # Parse date to help with shoe assignment
  date = Date.from_iso8601!(date_str)

  # Shoe Assignment Logic
  shoe_id =
    cond do
      # TRAIL runs get Tomir (Assuming even old ones mapped to "Trail" category for simplicity,
      # unless you want old trail runs to be null. We will map all Trails to Tomir for now as per request)
      surface == "trail" or type == "ultra" ->
        tomir.id

      # ASPHALT runs: Check date split
      true ->
        if Date.compare(date, ~D[2025-09-01]) == :lt do
          clifton8.id
        else
          clifton9.id
        end
    end

  # Set status to "completed" since these are from history
  # We define a race "report" automatically based on data to make it look nice
  report =
    if type == "other" do
      "Training run in #{city}."
    else
      "Race day! Covered #{dist}km with #{elev}m elevation gain. " <>
        if(elev > 1000, do: "Tough climbing today!", else: "Good pace.")
    end

  Racing.create_race(athlete, %{
    "name" => name,
    "race_date" => date,
    "race_type" => type,
    "status" => "completed",
    "country" => "Romania",
    "city" => city,
    "distance_km" => dist,
    "elevation_gain_m" => elev,
    "elevation_loss_m" => elev,
    "finish_time_seconds" => time,
    "surface_type" => surface,
    "terrain_difficulty" => difficulty,
    "weather_conditions" => "Clear",
    "temperature_celsius" => 15,
    "race_report" => report,
    # <--- Link the shoe!
    "shoe_id" => shoe_id
  })
end)

# 6. Recalculate shoe mileage after import
IO.puts("🔧 Recalculating shoe mileage...")
Racing.recalculate_shoe_mileage(tomir.id)
Racing.recalculate_shoe_mileage(clifton8.id)
Racing.recalculate_shoe_mileage(clifton9.id)

IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("🎉 SEED COMPLETE!")
IO.puts("Log in with: bogdan.blanaru97@gmail.com / H0YoUM7Lc5r2DwV.")
IO.puts(String.duplicate("=", 50) <> "\n")
