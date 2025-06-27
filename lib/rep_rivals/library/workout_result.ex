defmodule RepRivals.Library.WorkoutResult do
  use Ecto.Schema
  import Ecto.Changeset

  alias RepRivals.Library.Workout
  alias RepRivals.Accounts.User

  schema "workout_results" do
    field :result_value, :string
    field :notes, :string
    field :logged_at, :utc_datetime

    belongs_to :workout, Workout
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(workout_result, attrs) do
    workout_result
    |> cast(attrs, [:result_value, :notes, :logged_at, :workout_id, :user_id])
    |> validate_required([:result_value, :logged_at, :workout_id, :user_id])
    |> validate_length(:result_value, min: 1, max: 50)
    |> validate_length(:notes, max: 500)
    |> foreign_key_constraint(:workout_id)
    |> foreign_key_constraint(:user_id)
    |> validate_result_format()
  end

  defp validate_result_format(changeset) do
    case get_field(changeset, :result_value) do
      nil ->
        changeset

      value ->
        if valid_result_format?(value) do
          changeset
        else
          add_error(changeset, :result_value, "invalid format for result value")
        end
    end
  end

  defp valid_result_format?(value) when is_binary(value) do
    # Allow time format (8:45, 12:34:56), weight format (225, 225 lbs), reps format (150, 50 reps)
    String.match?(value, ~r/^(\d+:)*\d+(\.\d+)?(\s*(lbs?|kg|reps?))?$/i)
  end

  defp valid_result_format?(_), do: false
end
