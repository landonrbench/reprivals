defmodule RepRivalsWeb.WorkoutNotebookLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        RepRivals.PubSub,
        "workouts:#{socket.assigns.current_scope.user.id}"
      )
    end

    workouts = Library.list_workouts(socket.assigns.current_scope.user.id)

    {:ok,
     socket
     |> assign(:workouts, workouts)
     |> assign(:sort_by, "date")
     |> assign(:workouts_empty?, workouts == [])
     |> stream(:workouts, workouts)}
  end

  @impl true
  def handle_event("sort", %{"sort_by" => sort_by}, socket) do
    user_id = socket.assigns.current_scope.user.id
    workouts = get_sorted_workouts(user_id, sort_by)

    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign(:workouts_empty?, workouts == [])
     |> stream(:workouts, workouts, reset: true)}
  end

  @impl true
  def handle_event("create_workout", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/workouts/new")}
  end

  @impl true
  def handle_event("view_workout", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/workouts/#{id}/edit")}
  end

  @impl true
  def handle_info({:workout_created, workout}, socket) do
    {:noreply,
     socket
     |> assign(:workouts_empty?, false)
     |> stream_insert(:workouts, workout, at: 0)}
  end

  @impl true
  def handle_info({:workout_updated, workout}, socket) do
    {:noreply, stream_insert(socket, :workouts, workout)}
  end

  @impl true
  def handle_info({:workout_deleted, workout}, socket) do
    updated_socket = stream_delete(socket, :workouts, workout)

    # Check if workouts list is now empty
    remaining_workouts = Library.list_workouts(socket.assigns.current_scope.user.id)

    {:noreply,
     updated_socket
     |> assign(:workouts_empty?, remaining_workouts == [])}
  end

  defp get_sorted_workouts(user_id, sort_by) do
    case sort_by do
      "alphabetical" ->
        Library.list_workouts(user_id)
        |> Enum.sort_by(& &1.name, :asc)

      "date_created" ->
        Library.list_workouts(user_id)
        |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})

      "date_modified" ->
        Library.list_workouts(user_id)
        |> Enum.sort_by(& &1.updated_at, {:desc, DateTime})

      _default ->
        Library.list_workouts(user_id)
    end
  end

  defp format_date(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
    |> String.replace("-", "")
  end

  defp get_metric_color(metric) do
    case metric do
      "For Time" -> "bg-red-500"
      "For Reps" -> "bg-orange-500"
      "Weight" -> "bg-pink-500"
      _ -> "bg-gray-500"
    end
  end

  defp get_border_color(metric) do
    case metric do
      "For Time" -> "border-yellow-400"
      "For Reps" -> "border-orange-400"
      "Weight" -> "border-pink-400"
      _ -> "border-gray-400"
    end
  end
end
