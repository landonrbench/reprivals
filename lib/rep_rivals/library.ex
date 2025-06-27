defmodule RepRivals.Library do
  @moduledoc """
  The Library context handles workout operations.
  """

  import Ecto.Query, warn: false
  alias RepRivals.Repo

  alias RepRivals.Library.Workout
  alias RepRivals.Library.WorkoutResult

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
    case %Workout{}
         |> Workout.changeset(attrs)
         |> Repo.insert() do
      {:ok, workout} ->
        # Broadcast to all connected LiveViews for this user
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workouts:#{workout.user_id}",
          {:workout_created, workout}
        )

        {:ok, workout}

      error ->
        error
    end
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
    case workout
         |> Workout.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_workout} ->
        # Broadcast to all connected LiveViews for this user
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workouts:#{updated_workout.user_id}",
          {:workout_updated, updated_workout}
        )

        {:ok, updated_workout}

      error ->
        error
    end
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
    case Repo.delete(workout) do
      {:ok, deleted_workout} ->
        # Broadcast to all connected LiveViews for this user
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workouts:#{deleted_workout.user_id}",
          {:workout_deleted, deleted_workout}
        )

        {:ok, deleted_workout}

      error ->
        error
    end
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

  # Workout Results functions

  @doc """
  Returns the list of workout results for a specific workout, ordered by logged_at desc.

  ## Examples

      iex> list_workout_results(workout_id)
      [%WorkoutResult{}, ...]

  """
  def list_workout_results(workout_id) do
    WorkoutResult
    |> where([wr], wr.workout_id == ^workout_id)
    |> order_by([wr], desc: wr.logged_at)
    |> Repo.all()
  end

  @doc """
  Creates a workout result.

  ## Examples

      iex> create_workout_result(%{field: value})
      {:ok, %WorkoutResult{}}

      iex> create_workout_result(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workout_result(attrs \\ %{}) do
    case %WorkoutResult{}
         |> WorkoutResult.changeset(attrs)
         |> Repo.insert() do
      {:ok, workout_result} ->
        # Broadcast to all connected LiveViews for this workout
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workout_results:#{workout_result.workout_id}",
          {:workout_result_created, workout_result}
        )

        {:ok, workout_result}

      error ->
        error
    end
  end

  @doc """
  Updates a workout result.

  ## Examples

      iex> update_workout_result(workout_result, %{field: new_value})
      {:ok, %WorkoutResult{}}

      iex> update_workout_result(workout_result, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workout_result(%WorkoutResult{} = workout_result, attrs) do
    case workout_result
         |> WorkoutResult.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_result} ->
        # Broadcast to all connected LiveViews for this workout
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workout_results:#{updated_result.workout_id}",
          {:workout_result_updated, updated_result}
        )

        {:ok, updated_result}

      error ->
        error
    end
  end

  @doc """
  Deletes a workout result.

  ## Examples

      iex> delete_workout_result(workout_result)
      {:ok, %WorkoutResult{}}

      iex> delete_workout_result(workout_result)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workout_result(%WorkoutResult{} = workout_result) do
    case Repo.delete(workout_result) do
      {:ok, deleted_result} ->
        # Broadcast to all connected LiveViews for this workout
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workout_results:#{deleted_result.workout_id}",
          {:workout_result_deleted, deleted_result}
        )

        {:ok, deleted_result}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workout result changes.

  ## Examples

      iex> change_workout_result(workout_result)
      %Ecto.Changeset{}

  """
  def change_workout_result(%WorkoutResult{} = workout_result, attrs \\ %{}) do
    WorkoutResult.changeset(workout_result, attrs)
  end
end
