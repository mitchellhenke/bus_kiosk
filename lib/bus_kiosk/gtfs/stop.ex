defmodule BusKiosk.Gtfs.Stop do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias BusKiosk.Repo
  alias __MODULE__
  alias BusKiosk.Gtfs.{CalendarDate, StopTime, Trip}

  @schema_prefix "gtfs"
  @primary_key false
  schema "stops" do
    field :stop_id, :string
    field :stop_name, :string
    field :stop_lat, :float
    field :stop_lon, :float
    field :zone_id, :string
    field :stop_url, :string
    field :stop_desc, :string
    field :stop_code, :string
    field :timepoint, :string
    field :route_ids, {:array, :string}

    belongs_to :feed, BusKiosk.Gtfs.Feed
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :feed_id,
      :stop_id,
      :stop_name,
      :stop_lat,
      :stop_lon,
      :zone_id,
      :stop_url,
      :stop_desc,
      :timepoint,
      :route_ids
    ])
    |> validate_required([:feed_id, :stop_id, :stop_name, :stop_lat, :stop_lon])
    |> assoc_constraint(:feed)
  end

  def get_route_ids(stop, feed) do
    calendar_date = BusKiosk.Gtfs.CalendarDate.get_first_monday_calendar_date(feed)

    from(s in Stop,
      join: st in StopTime,
      on: st.feed_id == s.feed_id and st.stop_id == s.stop_id,
      join: t in Trip,
      on: t.feed_id == st.feed_id and t.trip_id == st.trip_id,
      join: cd in CalendarDate,
      on: cd.service_id == t.service_id and cd.feed_id == t.feed_id,
      where:
        cd.date == ^calendar_date.date and cd.feed_id == ^calendar_date.feed_id and
          s.stop_id == ^stop.stop_id,
      select: fragment("DISTINCT ?", t.route_id)
    )
    |> Repo.all()
  end

  def update_route_ids(stop, feed) do
    route_ids = get_route_ids(stop, feed)

    from(s in Stop, where: s.feed_id == ^feed.id and s.stop_id == ^stop.stop_id)
    |> Repo.update_all(set: [route_ids: route_ids])
  end

  def get_nearest(point) do
    feed = BusKiosk.Gtfs.Feed.get_first_after_date(Date.utc_today())

    {:ok, result} =
      Repo.query(
        """
        select s.*, (s.geom_point::geography <-> $1) * 3.28084 as distance, degrees(ST_Azimuth($1::geometry, s.geom_point)) as azimuth
        FROM gtfs.stops s
        WHERE s.feed_id = $2
        order by s.geom_point <-> $1
        LIMIT 20
        """,
        [point, feed.id]
      )

    columns = Enum.map(result.columns, &String.to_atom(&1))

    Enum.map(result.rows, fn row ->
      Enum.zip(columns, row)
      |> Enum.into(%{})
    end)
  end
end
