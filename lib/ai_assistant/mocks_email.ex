#mock email behivior
defmodule AiAssistant.Mailer.MockAdapter do
  @behaviour Swoosh.Adapter
  
  @impl Swoosh.Adapter
  def deliver(%Swoosh.Email{} = email, _config) do
    IO.inspect(email, label: "Email sent")
    {:ok, %{id: "console_log"}}
  end
end
