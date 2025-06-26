defmodule RepRivals.Repo do
  use Ecto.Repo,
    otp_app: :rep_rivals,
    adapter: Ecto.Adapters.SQLite3
end
