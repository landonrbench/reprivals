defmodule RepRivalsWeb.LeaderboardLive do
  use RepRivalsWeb, :live_view

  alias RepRivals.Library

  @impl true
  def mount(_params, _session, socket) do
    completed_challenges = Library.list_completed_challenges()

    {:ok,
     socket
     |> assign(:completed_challenges, completed_challenges)
     |> assign(:page_title, "Leaderboard")}
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

  defp place_emoji(1), do: "🥇"
  defp place_emoji(2), do: "🥈"
  defp place_emoji(3), do: "🥉"
  defp place_emoji(_), do: ""

  defp format_result_with_unit(result_value, result_unit) when is_nil(result_value) do
    "No result"
  end

  defp format_result_with_unit(result_value, result_unit) do
    formatted_value =
      if Decimal.decimal?(result_value) do
        result_value
        |> Decimal.to_string()
        |> String.replace(~r/\.?0+$/, "")
      else
        to_string(result_value)
      end

    case result_unit do
      nil -> formatted_value
      "" -> formatted_value
      unit -> "#{formatted_value} #{unit}"
    end
  end

  defp metric_description("For Time"), do: "⏱️ Fastest time wins"
  defp metric_description("AMRAP"), do: "🔄 Most rounds/reps wins"
  defp metric_description("Max Load"), do: "💪 Heaviest weight wins"
  defp metric_description(_), do: "🏆 Best result wins"
end
