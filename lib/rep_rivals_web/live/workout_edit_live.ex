defmodule RepRivalsWeb.WorkoutEditLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library
  alias RepRivals.Library.Workout

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    workout = Library.get_workout!(id)
    changeset = Library.change_workout(workout)

    {:ok,
     socket
     |> assign(:page_title, "Edit Workout")
     |> assign(:workout, workout)
     |> assign(:form, to_form(changeset))
     |> assign(:show_delete_modal, false)
     |> assign(:metric_options, [
       {"For Time", "For Time"},
       {"For Reps", "For Reps"},
       {"Weight", "Weight"}
     ])}
  end

  @impl true
  def handle_event("validate", %{"workout" => workout_params}, socket) do
    changeset =
      socket.assigns.workout
      |> Library.change_workout(workout_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"workout" => workout_params}, socket) do
    case Library.update_workout(socket.assigns.workout, workout_params) do
      {:ok, _workout} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workout updated successfully!")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/")}
  end

  @impl true
  def handle_event("show_delete_modal", _params, socket) do
    {:noreply, assign(socket, show_delete_modal: true)}
  end

  @impl true
  def handle_event("hide_delete_modal", _params, socket) do
    {:noreply, assign(socket, show_delete_modal: false)}
  end

  @impl true
  def handle_event("delete_workout", _params, socket) do
    case Library.delete_workout(socket.assigns.workout) do
      {:ok, _workout} ->
        {:noreply,
         socket
         |> put_flash(:info, "Workout deleted successfully!")
         |> push_navigate(to: ~p"/")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(show_delete_modal: false)
         |> put_flash(:error, "Failed to delete workout")}
    end
  end

  defp form_valid?(form) do
    # Check if form is valid and has required fields
    changeset = form.source
    name = Ecto.Changeset.get_field(changeset, :name) || form.params["name"]
    description = Ecto.Changeset.get_field(changeset, :description) || form.params["description"]
    metric = Ecto.Changeset.get_field(changeset, :metric) || form.params["metric"]

    # All fields are required for editing
    !is_nil(name) && name != "" &&
      !is_nil(description) && description != "" &&
      !is_nil(metric) && metric != ""
  end

  defp format_timestamp(datetime) do
    case datetime do
      nil -> "Unknown"
      dt -> Calendar.strftime(dt, "%b %d, %Y at %I:%M %p")
    end
  end
end
