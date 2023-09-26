defmodule AiAssistant.Repo do
  use Ecto.Repo,
    otp_app: :ai_assistant,
    adapter: Ecto.Adapters.Postgres
end
