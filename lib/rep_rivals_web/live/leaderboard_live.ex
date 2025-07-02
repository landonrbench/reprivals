defmodule RepRivalsWeb.LeaderboardLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library

  @impl true
  def mount(_params, _session, socket) do
    completed_challenges = Library.list_completed_challenges()

    {:ok,
     socket
     |> assign(:completed_challenges, completed_challenges)
     |> assign(:expanded_challenges, MapSet.new())
     |> assign(:page_title, "Leaderboard")}
  end

  @impl true
  def handle_event("toggle_challenge", %{"challenge_id" => challenge_id}, socket) do
    challenge_id = String.to_integer(challenge_id)
    expanded_challenges = socket.assigns.expanded_challenges

    updated_expanded =
      if MapSet.member?(expanded_challenges, challenge_id) do
        MapSet.delete(expanded_challenges, challenge_id)
      else
        MapSet.put(expanded_challenges, challenge_id)
      end

    {:noreply, assign(socket, :expanded_challenges, updated_expanded)}
  end

  @impl true
  def handle_info({:challenge_updated, _challenge}, socket) do
    # Refresh the completed challenges when any challenge is updated
    completed_challenges = Library.list_completed_challenges()
    {:noreply, assign(socket, :completed_challenges, completed_challenges)}
  end

  @impl true
  def handle_info({:participant_updated, _participant}, socket) do
    # Refresh the completed challenges when any participant is updated
    completed_challenges = Library.list_completed_challenges()
    {:noreply, assign(socket, :completed_challenges, completed_challenges)}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  defp challenge_expanded?(challenge_id, expanded_challenges) do
    MapSet.member?(expanded_challenges, challenge_id)
  end

  defp place_emoji(1), do: "🥇"
  defp place_emoji(2), do: "🥈"
  defp place_emoji(3), do: "🥉"
  defp place_emoji(_), do: ""

  defp format_result_with_unit(result_value, result_unit) when is_nil(result_value) do
    "No result"
  end

  defp format_result_with_unit(result_value, result_unit) do
    formatted_value =
      case result_value do
        %Decimal{} ->
          decimal_value = Decimal.to_float(result_value)
          format_time_or_value(decimal_value, result_unit)

        value when is_number(value) ->
          format_time_or_value(value, result_unit)

        _ ->
          to_string(result_value)
      end

    case result_unit do
      "seconds" -> formatted_value
      nil -> formatted_value
      "" -> formatted_value
      unit -> "#{formatted_value} #{unit}"
    end
  end

  defp format_time_or_value(value, "seconds") when is_number(value) do
    total_seconds = round(value)
    minutes = div(total_seconds, 60)
    seconds = rem(total_seconds, 60)
    "#{minutes}:#{String.pad_leading(to_string(seconds), 2, "0")}"
  end

  defp format_time_or_value(value, _unit) when is_number(value) do
    value
    |> to_string()
    |> String.replace(~r/\.?0+$/, "")
  end

  defp format_time_or_value(value, _unit) do
    to_string(value)
  end

  defp metric_description("For Time"), do: "⏱️ Fastest time wins"
  defp metric_description("AMRAP"), do: "🔄 Most rounds/reps wins"
  defp metric_description("Max Load"), do: "💪 Heaviest weight wins"
  defp metric_description(_), do: "🏆 Best result wins"
end
