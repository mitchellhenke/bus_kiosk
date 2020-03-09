defmodule BusKiosk.Gtfs.Shape do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 1, from: 2]
  alias BusKiosk.Repo

  @schema_prefix "gtfs"
  @primary_key false
  schema "shapes" do
    field :shape_id, :string
    field :shape_pt_lat, :float
    field :shape_pt_lon, :float
    field :shape_pt_sequence, :integer

    belongs_to :feed, BusKiosk.Gtfs.Feed
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:feed_id, :shape_id, :shape_pt_lat, :shape_pt_lon, :shape_pt_sequence])
    |> validate_required([:feed_id, :shape_id, :shape_pt_lat, :shape_pt_lon, :shape_pt_sequence])
    |> assoc_constraint(:feed)
  end
end
