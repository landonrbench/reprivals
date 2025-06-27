defmodule RepRivals.Repo.Migrations.CreateWorkoutResults do
  use Ecto.Migration

  def change do
    create table(:workout_results) do
      add :workout_id, references(:workouts, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :result_value, :string, null: false
      add :notes, :text
      add :logged_at, :utc_datetime, null: false

      timestamps()
    end

    create index(:workout_results, [:workout_id])
    create index(:workout_results, [:user_id])
    create index(:workout_results, [:logged_at])
  end
end
