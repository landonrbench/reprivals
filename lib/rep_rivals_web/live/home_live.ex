defmodule RepRivalsWeb.HomeLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    workouts = Library.list_workouts(user_id)

    # Get recent workouts (last 5)
    recent_workouts = Enum.take(workouts, 5)

    # Calculate stats
    total_workouts = length(workouts)

    # Get workouts from this week
    one_week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    this_week_count =
      workouts
      |> Enum.filter(fn workout ->
        DateTime.compare(workout.inserted_at, one_week_ago) == :gt
      end)
      |> length()

    {:ok,
     socket
     |> assign(:page_title, "RepRivals Dashboard")
     |> assign(:recent_workouts, recent_workouts)
     |> assign(:total_workouts, total_workouts)
     |> assign(:this_week_count, this_week_count)
     |> assign(:workouts_empty?, workouts == [])}
  end

  @impl true
  def handle_event("navigate_to_notebook", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/notebook")}
  end

  @impl true
  def handle_event("navigate_to_create", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/workouts/new")}
  end

  @impl true
  def handle_event("view_workout", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/workouts/#{id}")}
  end

  @impl true
  def handle_event("navigate_to_friends", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/friends")}
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
      "For Time" -> "border-red-400"
      "For Reps" -> "border-orange-400"
      "Weight" -> "border-pink-400"
      _ -> "border-gray-400"
    end
  end
end
