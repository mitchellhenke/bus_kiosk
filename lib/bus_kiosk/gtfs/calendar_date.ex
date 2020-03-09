defmodule BusKiosk.Gtfs.CalendarDate do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias __MODULE__
  alias BusKiosk.Repo

  @schema_prefix "gtfs"
  @primary_key false
  schema "calendar_dates" do
    field :service_id, :string
    field :date, :date
    field :exception_type, :integer

    belongs_to :feed, BusKiosk.Gtfs.Feed
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:feed_id, :service_id, :date, :exception_type])
    |> validate_required([:feed_id, :service_id, :date, :exception_type])
    |> assoc_constraint(:feed)
  end

  # dow is 0 indexed (0 = Sunday)
  def get_first_monday_calendar_date(feed) do
    from(c in CalendarDate,
      where: c.feed_id == ^feed.id and fragment("extract(dow from ?) = ?", c.date, 1),
      order_by: c.date,
      limit: 1
    )
    |> Repo.one!()
  end
end
