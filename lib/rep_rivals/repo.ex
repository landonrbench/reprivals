defmodule RepRivals.Repo do
  use Ecto.Repo,
    otp_app: :rep_rivals,
    adapter: Application.compile_env(:rep_rivals, :repo_adapter, Ecto.Adapters.Postgres)
end
