defmodule RepRivals.Library.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workouts" do
    field :name, :string
    field :description, :string
    field :metric, :string
    belongs_to :user, RepRivals.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [:name, :description, :metric, :user_id])
    |> validate_required([:name, :description, :metric, :user_id])
    |> validate_inclusion(:metric, ["For Time", "For Reps", "Weight"])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, min: 1, max: 1000)
  end
end
