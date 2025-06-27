defmodule RepRivals.Repo.Migrations.CreateChallengesAndParticipants do
  use Ecto.Migration

  def change do
    create table(:challenges) do
      add :name, :string, null: false
      add :description, :text
      add :workout_id, references(:workouts, on_delete: :delete_all), null: false
      add :creator_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, default: "active", null: false
      add :expires_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create table(:challenge_participants) do
      add :challenge_id, references(:challenges, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, default: "invited", null: false
      add :result_value, :decimal, precision: 10, scale: 2
      add :result_unit, :string
      add :result_notes, :text
      add :completed_at, :naive_datetime
      add :viewed_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:challenges, [:creator_id])
    create index(:challenges, [:workout_id])
    create index(:challenges, [:status])
    create index(:challenge_participants, [:challenge_id])
    create index(:challenge_participants, [:user_id])
    create index(:challenge_participants, [:status])
    create unique_index(:challenge_participants, [:challenge_id, :user_id])
  end
end
