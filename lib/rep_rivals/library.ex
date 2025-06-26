defmodule RepRivals.Library do
  @moduledoc """
  The Library context handles workout operations.
  """

  import Ecto.Query, warn: false
  alias RepRivals.Repo

  alias RepRivals.Library.Workout

  @doc """
  Returns the list of workouts for a specific user.

  ## Examples

      iex> list_workouts(user_id)
      [%Workout{}, ...]

  """
  def list_workouts(user_id) do
    Workout
    |> where([w], w.user_id == ^user_id)
    |> order_by([w], desc: w.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single workout.

  Raises `Ecto.NoResultsError` if the Workout does not exist.

  ## Examples

      iex> get_workout!(123)
      %Workout{}

      iex> get_workout!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workout!(id), do: Repo.get!(Workout, id)

  @doc """
  Creates a workout.

  ## Examples

      iex> create_workout(%{field: value})
      {:ok, %Workout{}}

      iex> create_workout(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workout(attrs \\ %{}) do
    %Workout{}
    |> Workout.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a workout.

  ## Examples

      iex> update_workout(workout, %{field: new_value})
      {:ok, %Workout{}}

      iex> update_workout(workout, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workout(%Workout{} = workout, attrs) do
    workout
    |> Workout.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a workout.

  ## Examples

      iex> delete_workout(workout)
      {:ok, %Workout{}}

      iex> delete_workout(workout)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workout(%Workout{} = workout) do
    Repo.delete(workout)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workout changes.

  ## Examples

      iex> change_workout(workout)
      %Ecto.ChangesetWorkout{}}

  """
  def change_workout(%Workout{} = workout, attrs \\ %{}) do
    Workout.changeset(workout, attrs)
  end
end
