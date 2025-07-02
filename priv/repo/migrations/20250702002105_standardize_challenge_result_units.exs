defmodule RepRivals.Repo.Migrations.StandardizeChallengeResultUnits do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # First, let's update all existing challenge participants with proper units based on workout metric
    execute """
    UPDATE challenge_participants 
    SET result_unit = 'seconds'
    FROM challenges c
    JOIN workouts w ON c.workout_id = w.id
    WHERE challenge_participants.challenge_id = c.id 
    AND w.metric = 'For Time'
    AND challenge_participants.result_unit = 'minutes'
    """

    # Convert minutes to seconds for time-based results
    execute """
    UPDATE challenge_participants 
    SET result_value = result_value * 60
    FROM challenges c
    JOIN workouts w ON c.workout_id = w.id
    WHERE challenge_participants.challenge_id = c.id 
    AND w.metric = 'For Time'
    AND challenge_participants.result_unit = 'seconds'
    """

    # Set units for weight-based workouts
    execute """
    UPDATE challenge_participants 
    SET result_unit = 'lbs'
    FROM challenges c
    JOIN workouts w ON c.workout_id = w.id
    WHERE challenge_participants.challenge_id = c.id 
    AND w.metric = 'Weight'
    AND challenge_participants.result_unit IS NULL
    """

    # Set units for rep-based workouts
    execute """
    UPDATE challenge_participants 
    SET result_unit = 'reps'
    FROM challenges c
    JOIN workouts w ON c.workout_id = w.id
    WHERE challenge_participants.challenge_id = c.id 
    AND w.metric = 'For Reps'
    AND challenge_participants.result_unit IS NULL
    """
  end

  def down do
    # Convert seconds back to minutes for time-based results
    execute """
    UPDATE challenge_participants 
    SET result_value = result_value / 60,
        result_unit = 'minutes'
    FROM challenges c
    JOIN workouts w ON c.workout_id = w.id
    WHERE challenge_participants.challenge_id = c.id 
    AND w.metric = 'For Time'
    AND challenge_participants.result_unit = 'seconds'
    """
  end
end
