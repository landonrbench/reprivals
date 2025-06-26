defmodule RepRivals.Repo.Migrations.CreateWorkouts do
  use Ecto.Migration

  def change do
    create table(:workouts) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :metric, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:workouts, [:user_id])
    create index(:workouts, [:inserted_at])
  end
end
