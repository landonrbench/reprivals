# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     RepRivals.Repo.insert!(%RepRivals.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query, warn: false
alias RepRivals.Repo
alias RepRivals.Accounts
alias RepRivals.Library
alias RepRivals.Accounts

# Create a sample user if one doesn't exist
{:ok, user} =
  case Repo.get_by(RepRivals.Accounts.User, email: "demo@reprivals.com") do
    nil ->
      Accounts.register_user(%{
        email: "demo@reprivals.com",
        password: "password123456"
      })

    user ->
      {:ok, user}
  end

# Create additional test users for friend functionality
test_users = [
  %{email: "alice@example.com", password: "password123456"},
  %{email: "bob@example.com", password: "password123456"},
  %{email: "charlie@example.com", password: "password123456"},
  %{email: "diana@example.com", password: "password123456"},
  %{email: "eve@example.com", password: "password123456"}
]

Enum.each(test_users, fn user_attrs ->
  case Repo.get_by(RepRivals.Accounts.User, email: user_attrs.email) do
    nil ->
      case Accounts.register_user(user_attrs) do
        {:ok, new_user} ->
          IO.puts("Created test user: #{new_user.email}")

        {:error, changeset} ->
          IO.puts("Failed to create user #{user_attrs.email}: #{inspect(changeset.errors)}")
      end

    _existing_user ->
      IO.puts("Test user already exists: #{user_attrs.email}")
  end
end)

# Create sample workouts
sample_workouts = [
  %{
    name: "HELEN",
    description: "3 rounds for time: 400m run, 21 kettlebell swings (53/35 lbs), 12 pull-ups",
    metric: "For Time",
    user_id: user.id
  },
  %{
    name: "JACKIE",
    description: "For time: 1000m row, 50 thrusters (45/35 lbs), 30 pull-ups",
    metric: "For Time",
    user_id: user.id
  },
  %{
    name: "FILTHY FIFTY",
    description:
      "50 reps each: box jumps (24/20), jumping pull-ups, kettlebell swings (35/26), walking lunges, knees-to-elbows, push press (45/35), back extensions, wall balls (20/14), burpees, double-unders",
    metric: "For Time",
    user_id: user.id
  },
  %{
    name: "WITTMAN",
    description:
      "7 rounds for time: 5 muscle-ups, 10 handstand push-ups, 15 kettlebell swings (70/53 lbs)",
    metric: "For Time",
    user_id: user.id
  },
  %{
    name: "MAX DEADLIFT",
    description:
      "Work up to 1RM deadlift. Start with warm-up sets, then gradually increase weight until you reach your maximum single rep.",
    metric: "Weight",
    user_id: user.id
  },
  %{
    name: "PULLUP LADDER",
    description:
      "Perform 1 pull-up, rest 10 seconds, 2 pull-ups, rest 20 seconds, 3 pull-ups, rest 30 seconds... continue until failure.",
    metric: "For Reps",
    user_id: user.id
  }
]

Enum.each(sample_workouts, fn workout_attrs ->
  case Library.create_workout(workout_attrs) do
    {:ok, workout} ->
      IO.puts("Created workout: #{workout.name}")

    {:error, changeset} ->
      IO.puts("Failed to create workout: #{inspect(changeset.errors)}")
  end
end)

IO.puts("Seeding complete!")
IO.puts("\n=== Test Users Created ===")
IO.puts("You can now test friend functionality with these emails:")
IO.puts("- alice@example.com")
IO.puts("- bob@example.com")
IO.puts("- charlie@example.com")
IO.puts("- diana@example.com")
IO.puts("- eve@example.com")
IO.puts("All passwords: password123456")
