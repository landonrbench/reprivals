defmodule RepRivalsWeb.WorkoutNewLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library
  alias RepRivals.Library.Workout

  @impl true
  def mount(_params, _session, socket) do
    # Generate default name as current date in YYYYMMDD format
    default_name = Date.utc_today() |> Date.to_string() |> String.replace("-", "")

    changeset = Library.change_workout(%Workout{})

    {:ok,
     socket
     |> assign(:page_title, "Create New Workout")
     |> assign(:default_name, default_name)
     |> assign(:form, to_form(changeset))
     |> assign(:metric_options, [
       {"For Time", "For Time"},
       {"For Reps", "For Reps"},
       {"Weight", "Weight"}
     ])}
  end

  @impl true
  def handle_event("validate", %{"workout" => workout_params}, socket) do
    # Use default name if name is empty
    workout_params =
      if workout_params["name"] == "" do
        Map.put(workout_params, "name", socket.assigns.default_name)
      else
        workout_params
      end

    changeset =
      %Workout{}
      |> Library.change_workout(workout_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"workout" => workout_params}, socket) do
    # Use default name if name is empty
    workout_params =
      if workout_params["name"] == "" do
        Map.put(workout_params, "name", socket.assigns.default_name)
      else
        workout_params
      end

    # Add current user ID to the workout
    workout_params = Map.put(workout_params, "user_id", socket.assigns.current_scope.user.id)

    case Library.create_workout(workout_params) do
      {:ok, _workout} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workout created successfully!")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  defp form_valid?(form) do
    # Check if form is valid and has required fields
    changeset = form.source
    name = Ecto.Changeset.get_field(changeset, :name) || form.params["name"]
    description = Ecto.Changeset.get_field(changeset, :description) || form.params["description"]
    metric = Ecto.Changeset.get_field(changeset, :metric) || form.params["metric"]

    # Name can be empty (will use default), but description and metric are required
    !is_nil(description) && description != "" &&
      !is_nil(metric) && metric != ""
  end
end
