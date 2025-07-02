defmodule RepRivals.Library do
  @moduledoc """
  The Library context.
  """

  import Ecto.Query, warn: false
  alias RepRivals.Repo

  alias RepRivals.Library.Workout
  alias RepRivals.Library.WorkoutResult
  alias RepRivals.Library.Challenge
  alias RepRivals.Library.ChallengeParticipant

  @doc """
  Returns the list of workouts.

  ## Examples

      iex> list_workouts()
      [%Workout{}, ...]

  """
  def list_workouts do
    Repo.all(Workout)
  end

  @doc """
  Returns the list of workouts for a specific user.

  ## Examples

      iex> list_workouts_for_user(user_id)
      [%Workout{}, ...]

  """
  def list_workouts_for_user(user_id) do
    Workout
    |> where([w], w.user_id == ^user_id)
    |> order_by([w], desc: w.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of workouts for a specific user filtered by search term.

  ## Examples

      iex> search_workouts_for_user(user_id, "push")
      [%Workout{}, ...]

  """
  def search_workouts_for_user(user_id, search_term) when is_binary(search_term) do
    search_pattern = "%#{search_term}%"

    Workout
    |> where([w], w.user_id == ^user_id)
    |> where([w], ilike(w.name, ^search_pattern))
    |> order_by([w], desc: w.inserted_at)
    |> Repo.all()
  end

  def search_workouts_for_user(user_id, _), do: list_workouts_for_user(user_id)

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
  Gets a single workout with preloaded results.

  ## Examples

      iex> get_workout_with_results!(123)
      %Workout{results: [%WorkoutResult{}, ...]}

  """
  def get_workout_with_results!(id) do
    Workout
    |> where([w], w.id == ^id)
    |> preload(:results)
    |> Repo.one!()
  end

  @doc """
  Creates a workout.

  ## Examples

      iex> create_workout(%{field: value})
      {:ok, %Workout{}}

      iex> create_workout(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workout(attrs \\ %{}) do
    result =
      %Workout{}
      |> Workout.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, workout} ->
        Phoenix.PubSub.broadcast(RepRivals.PubSub, "workouts", {:workout_created, workout})
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
    result =
      workout
      |> Workout.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_workout} ->
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workouts",
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
    result = Repo.delete(workout)

    case result do
      {:ok, deleted_workout} ->
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workouts",
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
      %Ecto.Changeset{}

  """
  def change_workout(%Workout{} = workout, attrs \\ %{}) do
    Workout.changeset(workout, attrs)
  end

  @doc """
  Returns the list of workout_results for a specific workout.

  ## Examples

      iex> list_workout_results(workout_id)
      [%WorkoutResult{}, ...]

  """
  def list_workout_results(workout_id) do
    WorkoutResult
    |> where([wr], wr.workout_id == ^workout_id)
    |> order_by([wr], desc: wr.logged_at, desc: wr.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single workout_result.

  Raises `Ecto.NoResultsError` if the Workout result does not exist.

  ## Examples

      iex> get_workout_result!(123)
      %WorkoutResult{}

      iex> get_workout_result!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workout_result!(id), do: Repo.get!(WorkoutResult, id)

  @doc """
  Creates a workout_result.

  ## Examples

      iex> create_workout_result(%{field: value})
      {:ok, %WorkoutResult{}}

      iex> create_workout_result(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_workout_result(attrs \\ %{}) do
    result =
      %WorkoutResult{}
      |> WorkoutResult.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, workout_result} ->
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workout_results",
          {:result_created, workout_result}
        )

        {:ok, workout_result}

      error ->
        error
    end
  end

  @doc """
  Updates a workout_result.

  ## Examples

      iex> update_workout_result(workout_result, %{field: new_value})
      {:ok, %WorkoutResult{}}

      iex> update_workout_result(workout_result, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_workout_result(%WorkoutResult{} = workout_result, attrs) do
    result =
      workout_result
      |> WorkoutResult.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_result} ->
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workout_results",
          {:result_updated, updated_result}
        )

        {:ok, updated_result}

      error ->
        error
    end
  end

  @doc """
  Deletes a workout_result.

  ## Examples

      iex> delete_workout_result(workout_result)
      {:ok, %WorkoutResult{}}

      iex> delete_workout_result(workout_result)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workout_result(%WorkoutResult{} = workout_result) do
    result = Repo.delete(workout_result)

    case result do
      {:ok, deleted_result} ->
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "workout_results",
          {:result_deleted, deleted_result}
        )

        {:ok, deleted_result}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workout_result changes.

  ## Examples

      iex> change_workout_result(workout_result)
      %Ecto.Changeset{data: %WorkoutResult{}}

  """
  def change_workout_result(%WorkoutResult{} = workout_result, attrs \\ %{}) do
    WorkoutResult.changeset(workout_result, attrs)
  end

  ## Challenge functions

  @doc """
  Returns the list of challenges for a specific user (created by them).

  ## Examples

      iex> list_challenges_for_user(user_id)
      [%Challenge{}, ...]

  """
  def list_challenges_for_user(user_id) do
    Challenge
    |> where([c], c.creator_id == ^user_id)
    |> preload([:workout, :creator, participants: [:user]])
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of challenge invites for a specific user (challenges they were invited to).

  ## Examples

      iex> list_challenge_invites_for_user(user_id)
      [%ChallengeParticipant{}, ...]

  """
  def list_challenge_invites_for_user(user_id) do
    ChallengeParticipant
    |> where([cp], cp.user_id == ^user_id)
    |> preload(challenge: [:workout, :creator, participants: [:user]])
    |> order_by([cp], desc: cp.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets challenge invites that are unviewed for a user (for notification badge).

  ## Examples

      iex> get_unviewed_challenge_count(user_id)
      3

  """
  def get_unviewed_challenge_count(user_id) do
    ChallengeParticipant
    |> where([cp], cp.user_id == ^user_id and is_nil(cp.viewed_at))
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a single challenge with all participants.

  ## Examples

      iex> get_challenge_with_participants!(123)
      %Challenge{participants: [%ChallengeParticipant{}, ...]}

  """
  def get_challenge_with_participants!(id) do
    Challenge
    |> where([c], c.id == ^id)
    |> preload([:workout, :creator, participants: [:user]])
    |> Repo.one!()
  end

  @doc """
  Gets a single challenge.

  Raises `Ecto.NoResultsError` if the Challenge does not exist.

  ## Examples

      iex> get_challenge!(123)
      %Challenge{}

      iex> get_challenge!(456)
      ** (Ecto.NoResultsError)

  """
  def get_challenge!(id), do: Repo.get!(Challenge, id)

  @doc """
  Returns the list of challenge participants for a specific challenge.

  ## Examples

      iex> list_challenge_participants(challenge_id)
      [%ChallengeParticipant{}, ...]

  """
  def list_challenge_participants(challenge_id) do
    ChallengeParticipant
    |> where([cp], cp.challenge_id == ^challenge_id)
    |> preload([:user])
    |> Repo.all()
  end

  @doc """
  Updates a challenge.

  ## Examples

      iex> update_challenge(challenge, %{field: new_value})
      {:ok, %Challenge{}}

      iex> update_challenge(challenge, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_challenge(%Challenge{} = challenge, attrs) do
    result =
      challenge
      |> Challenge.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_challenge} ->
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "challenges",
          {:challenge_updated, updated_challenge}
        )

        {:ok, updated_challenge}

      error ->
        error
    end
  end

  @doc """
  Gets a single challenge participant.

  ## Examples

      iex> get_challenge_participant!(123)
      %ChallengeParticipant{}

  """
  def get_challenge_participant!(id) do
    ChallengeParticipant
    |> where([cp], cp.id == ^id)
    |> preload([:challenge, :user])
    |> Repo.one!()
  end

  @doc """
  Returns the list of completed challenges (where all participants have finished).
  Results are sorted by completion order for leaderboard display.

  ## Examples

      iex> list_completed_challenges()
      [%Challenge{}, ...]

  """
  def list_completed_challenges do
    # Get challenges where all participants have status "completed"
    challenge_ids_with_all_completed =
      from(c in Challenge,
        left_join: p in ChallengeParticipant,
        on: p.challenge_id == c.id,
        group_by: c.id,
        having: fragment("COUNT(*) = COUNT(CASE WHEN ? = 'completed' THEN 1 END)", p.status),
        select: c.id
      )
      |> Repo.all()

    # Fetch the full challenge data with participants sorted by result
    Challenge
    |> where([c], c.id in ^challenge_ids_with_all_completed)
    |> preload([
      :workout,
      :creator,
      participants:
        ^from(p in ChallengeParticipant,
          order_by: [asc: p.result_value],
          preload: [:user]
        )
    ])
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
    |> Enum.map(&sort_challenge_participants/1)
  end

  # Private function to sort participants by their result based on workout metric
  defp sort_challenge_participants(%Challenge{workout: %{metric: "For Time"}} = challenge) do
    # For time-based workouts, lowest time wins (ascending order)
    sorted_participants =
      challenge.participants
      |> Enum.sort_by(fn p ->
        case p.result_value do
          # Put nil results at the end
          nil -> 999_999
          value -> Decimal.to_float(value)
        end
      end)

    %{challenge | participants: sorted_participants}
  end

  defp sort_challenge_participants(%Challenge{workout: %{metric: "AMRAP"}} = challenge) do
    # For AMRAP workouts, highest score wins (descending order)
    sorted_participants =
      challenge.participants
      |> Enum.sort_by(
        fn p ->
          case p.result_value do
            # Put nil results at the end
            nil -> -1
            value -> Decimal.to_float(value)
          end
        end,
        :desc
      )

    %{challenge | participants: sorted_participants}
  end

  defp sort_challenge_participants(%Challenge{workout: %{metric: "Max Load"}} = challenge) do
    # For max load workouts, highest weight wins (descending order)
    sorted_participants =
      challenge.participants
      |> Enum.sort_by(
        fn p ->
          case p.result_value do
            # Put nil results at the end
            nil -> -1
            value -> Decimal.to_float(value)
          end
        end,
        :desc
      )

    %{challenge | participants: sorted_participants}
  end

  defp sort_challenge_participants(challenge) do
    # Default sorting for unknown metrics (ascending by result_value)
    sorted_participants =
      challenge.participants
      |> Enum.sort_by(fn p ->
        case p.result_value do
          nil -> 999_999
          value -> Decimal.to_float(value)
        end
      end)

    %{challenge | participants: sorted_participants}
  end

  @doc """
  Creates a challenge.

  ## Examples

      iex> create_challenge(%{field: value})
      {:ok, %Challenge{}}

      iex> create_challenge(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_challenge(attrs \\ %{}) do
    result =
      %Challenge{}
      |> Challenge.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, challenge} ->
        Phoenix.PubSub.broadcast(RepRivals.PubSub, "challenges", {:challenge_created, challenge})
        {:ok, challenge}

      error ->
        error
    end
  end

  @doc """
  Creates a pre-workout challenge where the creator also participates.
  This is for "let's all do this workout together" scenarios.

  ## Examples

      iex> create_group_challenge(%{name: "Morning Workout", workout_id: 1, creator_id: 1}, [2, 3])
      {:ok, %Challenge{}}

  """
  def create_group_challenge(challenge_attrs, participant_user_ids) do
    Repo.transaction(fn ->
      # Create the challenge
      case create_challenge(challenge_attrs) do
        {:ok, challenge} ->
          # Add all participants including the creator
          creator_id = challenge_attrs[:creator_id] || challenge_attrs["creator_id"]
          all_participant_ids = [creator_id | participant_user_ids] |> Enum.uniq()

          case create_challenge_participants(challenge.id, all_participant_ids) do
            {:ok, _participants} -> challenge
            {:error, error} -> Repo.rollback(error)
          end

        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end

  @doc """
  Creates a post-workout challenge from an existing workout result.
  The creator's result is automatically completed.

  ## Examples

      iex> create_challenge_from_result(workout_result, [2, 3])
      {:ok, %Challenge{}}

  """
  def create_challenge_from_result(%WorkoutResult{} = workout_result, participant_user_ids) do
    Repo.transaction(fn ->
      # Preload workout and user
      workout_result = Repo.preload(workout_result, [:workout, :user])

      # Create challenge attrs from the workout result
      challenge_attrs = %{
        name: "Beat My #{workout_result.workout.name} Score!",
        description: "I just completed this workout - can you beat my result?",
        status: "active",
        creator_id: workout_result.user_id,
        workout_id: workout_result.workout_id
      }

      # Create the challenge
      case create_challenge(challenge_attrs) do
        {:ok, challenge} ->
          # Create the creator as a completed participant
          creator_participant_attrs = %{
            challenge_id: challenge.id,
            user_id: workout_result.user_id,
            status: "completed",
            result_value: workout_result.result_value,
            result_unit: Map.get(workout_result, :result_unit, nil),
            result_notes: workout_result.notes,
            completed_at: workout_result.logged_at,
            inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
            updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
          }

          # Insert creator participant
          case Repo.insert_all(ChallengeParticipant, [creator_participant_attrs], returning: true) do
            {1, [_creator_participant]} ->
              # Create invited participants
              case create_challenge_participants(challenge.id, participant_user_ids) do
                {:ok, _participants} -> challenge
                {:error, error} -> Repo.rollback(error)
              end

            error ->
              Repo.rollback(error)
          end

        {:error, error} ->
          Repo.rollback(error)
      end
    end)
  end

  @doc """
  Creates challenge participants for a list of user IDs.

  ## Examples

      iex> create_challenge_participants(challenge_id, [1, 2, 3])
      {:ok, [%ChallengeParticipant{}, ...]}

  """
  def create_challenge_participants(challenge_id, user_ids) do
    participants =
      Enum.map(user_ids, fn user_id ->
        %{
          challenge_id: challenge_id,
          user_id: user_id,
          status: "invited",
          inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
          updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
        }
      end)

    case Repo.insert_all(ChallengeParticipant, participants, returning: true) do
      {_count, participants} ->
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "challenges",
          {:participants_invited, participants}
        )

        {:ok, participants}

      error ->
        error
    end
  end

  @doc """
  Updates a challenge participant (accept/decline/complete).

  ## Examples

      iex> update_challenge_participant(participant, %{status: "accepted"})
      {:ok, %ChallengeParticipant{}}

  """
  def update_challenge_participant(%ChallengeParticipant{} = participant, attrs) do
    result =
      participant
      |> ChallengeParticipant.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated_participant} ->
        Phoenix.PubSub.broadcast(
          RepRivals.PubSub,
          "challenges",
          {:participant_updated, updated_participant}
        )

        {:ok, updated_participant}

      error ->
        error
    end
  end

  @doc """
  Mark challenge invite as viewed (removes from notification count).

  ## Examples

      iex> mark_challenge_viewed(participant)
      {:ok, %ChallengeParticipant{}}

  """
  def mark_challenge_viewed(%ChallengeParticipant{} = participant) do
    update_challenge_participant(participant, %{viewed_at: NaiveDateTime.utc_now()})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking challenge changes.

  ## Examples

      iex> change_challenge(challenge)
      %Ecto.Changeset{}

  """
  def change_challenge(%Challenge{} = challenge, attrs \\ %{}) do
    Challenge.changeset(challenge, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking challenge participant changes.

  ## Examples

      iex> change_challenge_participant(participant)
      %Ecto.Changeset{}

  """
  def change_challenge_participant(%ChallengeParticipant{} = participant, attrs \\ %{}) do
    ChallengeParticipant.changeset(participant, attrs)
  end
end
