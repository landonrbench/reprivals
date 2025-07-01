defmodule RepRivals.Repo.Migrations.CreateFriends do
  use Ecto.Migration

  def change do
    create table(:friends) do
      add :requester_id, references(:users, on_delete: :delete_all), null: false
      add :recipient_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"

      timestamps()
    end

    create index(:friends, [:requester_id])
    create index(:friends, [:recipient_id])
    create index(:friends, [:status])

    # Ensure users can't friend themselves and no duplicate requests
    create unique_index(:friends, [:requester_id, :recipient_id])

    # Note: Check constraint removed for SQLite compatibility
    # Status validation will be handled at the application level
  end
end
