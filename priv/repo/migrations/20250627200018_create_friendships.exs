defmodule RepRivals.Repo.Migrations.CreateFriendships do
  use Ecto.Migration

  def change do
    create table(:friendships) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :friend_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"

      timestamps()
    end

    create index(:friendships, [:user_id])
    create index(:friendships, [:friend_id])
    create index(:friendships, [:status])
    create unique_index(:friendships, [:user_id, :friend_id])
  end
end
