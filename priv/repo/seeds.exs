# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
import Ecto.Query, warn: false

alias KoveRiders.Repo
alias KoveRiders.Bikes.{Engine, Bike}

# ── Engine definitions ────────────────────────────────────────────────────────

engines_data = [
  %{
    type: "Single cylinder, 4-stroke, DOHC",
    displacement_cc: 450,
    bore_mm: 97.0,
    stroke_mm: 60.8,
    compression_ratio: "13.6:1",
    max_power_hp: 46.0,
    max_power_rpm: 9500,
    max_torque_nm: 42.0,
    max_torque_rpm: 7000,
    cooling: "Liquid cooled",
    transmission: "6-speed",
    fuel_system: "EFI"
  },
  %{
    type: "Single cylinder, 4-stroke, DOHC",
    displacement_cc: 500,
    bore_mm: 89.0,
    stroke_mm: 80.6,
    compression_ratio: "11.5:1",
    max_power_hp: 47.6,
    max_power_rpm: 8000,
    max_torque_nm: 50.0,
    max_torque_rpm: 6500,
    cooling: "Liquid cooled",
    transmission: "6-speed",
    fuel_system: "EFI"
  },
  %{
    type: "Parallel twin, 4-stroke, DOHC",
    displacement_cc: 800,
    bore_mm: 94.0,
    stroke_mm: 57.9,
    compression_ratio: "13.0:1",
    max_power_hp: 94.0,
    max_power_rpm: 10500,
    max_torque_nm: 78.0,
    max_torque_rpm: 8000,
    cooling: "Liquid cooled",
    transmission: "6-speed",
    fuel_system: "EFI"
  },
  %{
    type: "Single cylinder, 4-stroke, DOHC",
    displacement_cc: 250,
    bore_mm: 76.0,
    stroke_mm: 55.2,
    compression_ratio: "12.8:1",
    max_power_hp: 28.0,
    max_power_rpm: 9800,
    max_torque_nm: 24.0,
    max_torque_rpm: 7500,
    cooling: "Liquid cooled",
    transmission: "6-speed",
    fuel_system: "EFI"
  },
  %{
    type: "Single cylinder, 4-stroke, DOHC",
    displacement_cc: 450,
    bore_mm: 97.0,
    stroke_mm: 60.8,
    compression_ratio: "13.6:1",
    max_power_hp: 52.0,
    max_power_rpm: 9800,
    max_torque_nm: 44.0,
    max_torque_rpm: 7000,
    cooling: "Liquid cooled",
    transmission: "6-speed",
    fuel_system: "EFI"
  },
  %{
    type: "Parallel twin, 4-stroke, DOHC",
    displacement_cc: 800,
    bore_mm: 94.0,
    stroke_mm: 57.9,
    compression_ratio: "13.0:1",
    max_power_hp: 91.0,
    max_power_rpm: 10000,
    max_torque_nm: 80.0,
    max_torque_rpm: 7500,
    cooling: "Liquid cooled",
    transmission: "6-speed",
    fuel_system: "EFI"
  }
]

engines =
  Enum.map(engines_data, fn attrs ->
    case Repo.get_by(Engine,
           displacement_cc: attrs.displacement_cc,
           type: attrs.type,
           max_power_hp: attrs.max_power_hp
         ) do
      nil -> Repo.insert!(Engine.changeset(%Engine{}, attrs))
      existing -> existing
    end
  end)

IO.puts("Seeded #{length(engines)} engines")

# ── Bike models ───────────────────────────────────────────────────────────────

bike_models = [
  %{name: "450X Rally", slug_base: "450x-rally", engine_idx: 0, msrp_cents: 649_900},
  %{name: "500X Rally", slug_base: "500x-rally", engine_idx: 1, msrp_cents: 749_900},
  %{name: "800X Rally", slug_base: "800x-rally", engine_idx: 2, msrp_cents: 1_049_900},
  %{name: "250X Rally", slug_base: "250x-rally", engine_idx: 3, msrp_cents: 499_900},
  %{name: "450SR", slug_base: "450sr", engine_idx: 4, msrp_cents: 699_900},
  %{name: "800SR", slug_base: "800sr", engine_idx: 5, msrp_cents: 1_099_900}
]

years = 2022..2026

bike_count =
  Enum.reduce(bike_models, 0, fn model, acc ->
    engine = Enum.at(engines, model.engine_idx)

    Enum.reduce(years, acc, fn year, inner_acc ->
      slug = "#{year}-kove-#{model.slug_base}"

      case Repo.get_by(Bike, slug: slug) do
        nil ->
          Repo.insert!(%Bike{
            name: model.name,
            slug: slug,
            year: year,
            msrp_cents: model.msrp_cents,
            tagline: "#{year} Kove #{model.name}",
            color: "Competition Orange",
            engine_id: engine.id
          })

          inner_acc + 1

        _existing ->
          inner_acc
      end
    end)
  end)

IO.puts("Seeded #{bike_count} bikes (#{Enum.count(years)} years × #{length(bike_models)} models)")
IO.puts("Total bikes in DB: #{Repo.aggregate(Bike, :count)}")
