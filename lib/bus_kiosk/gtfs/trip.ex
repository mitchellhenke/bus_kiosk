defmodule BusKiosk.Gtfs.Trip do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias BusKiosk.Repo

  # alias Transit.{ShapeGeom, Stop, StopTime}

  @schema_prefix "gtfs"
  @primary_key false
  schema "trips" do
    field :trip_id, :string
    field :service_id, :string
    field :trip_headsign, :string
    field :direction_id, :integer
    field :block_id, :string
    field :length_seconds, :integer
    field :start_time, Interval
    field :end_time, Interval
    field :shape_id, :string

    belongs_to :feed, BusKiosk.Gtfs.Feed

    # belongs_to :shape_geom, Transit.ShapeGeom, references: :shape_id, foreign_key: :shape_id, type: :string
    belongs_to :route, BusKiosk.Gtfs.Route,
      references: :route_id,
      foreign_key: :route_id,
      type: :string

    # has_many :stop_times, Transit.StopTime, references: :trip_id, foreign_key: :trip_id
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :feed_id,
      :trip_id,
      :route_id,
      :service_id,
      :trip_headsign,
      :direction_id,
      :block_id,
      :shape_id
    ])
    |> validate_required([
      :feed_id,
      :trip_id,
      :route_id,
      :service_id,
      :direction_id,
      :block_id,
      :shape_id
    ])
    |> assoc_constraint(:feed)
  end
end
