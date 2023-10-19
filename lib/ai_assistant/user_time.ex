defmodule AiAssistant.UserTimeZone do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_time_zones" do
    belongs_to :user, AiAssistant.Accounts.User
    field :time_diff_minutes, :integer

    timestamps()
  end

  def changeset(user_time_zone, attrs) do
    user_time_zone
    |> cast(attrs, [:user_id, :time_diff_minutes])
    |> validate_required([:user_id, :time_diff_minutes])
  end
end

defmodule AiAssistant.UserTime do
  alias AiAssistant.Repo
  #alias AiAssistant.User
  alias AiAssistant.UserTimeZone

  #import Ecto.Query, only: [from: 2]

  @doc """
  Updates the time zone information for a user.
  """
  def upsert_user_time(user_id, user_provided_time) do
    # Calculate the difference in minutes between the user's time and the current UTC time
    time_diff_minutes = diff_in_minutes(user_provided_time,DateTime.utc_now())

    attrs = %{#UserTimeZone
      user_id: user_id,
      time_diff_minutes: time_diff_minutes
    }

    case Repo.get_by(UserTimeZone, user_id: user_id) do
      nil ->
        changeset = UserTimeZone.changeset(%UserTimeZone{}, attrs) 
        Repo.insert(changeset)
      existing ->
        # For an existing record, we use the attrs to update the existing data
        changeset = UserTimeZone.changeset(existing, attrs)
        Repo.update(changeset)
        IO.puts('updated time sucessfuly')
    end
  end

  @doc """
  Retrieves the estimated local time for a user.
  """
  def get_user_local_time(user_id) do
    case Repo.get_by(UserTimeZone, user_id: user_id) do
      nil -> 
        nil
      user_time_zone ->
        utc_time = DateTime.utc_now()
        DateTime.add(utc_time, user_time_zone.time_diff_minutes * 60, :second)
    end
  end

  defp diff_in_minutes(time1, time2) do
    DateTime.diff(time1, time2, :minute)
  end
end
