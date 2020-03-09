defmodule BusKiosk.Gtfs do
  require Logger
  alias BusKiosk.Repo
  import Ecto.Query

  alias BusKiosk.Gtfs.{CalendarDate, Feed, Route, Stop, StopTime, Trip}

  def download_and_import_gtfs(url, date) do
    with {:ok, feed} <- Feed.find_or_create(date),
         {:ok, directory} <- download_gtfs(url, feed),
         :ok <- import_gtfs(directory, feed) do
      :ok
    end
  end

  def download_gtfs(url, feed) do
    directory = "/tmp/gtfs_#{feed.date}"
    destination = "/tmp/gtfs_#{feed.date}/transit.zip"

    with :ok <- File.mkdir_p(directory),
         {:ok, %{status_code: 302, headers: headers}} <- Mojito.request(method: :get, url: url),
         location <- Mojito.Headers.get(headers, "location"),
         {:ok, %{status_code: 200, body: body}} <- Mojito.request(method: :get, url: location),
         :ok <- File.write(destination, body),
         {:ok, _files} <- :zip.unzip(String.to_charlist(destination), cwd: directory) do
      {:ok, directory}
    else
      e ->
        Logger.error(inspect(e))
    end
  end

  def import_gtfs(directory, feed) do
    dates = load_calendar_dates(Path.join([directory, "calendar_dates.txt"]), feed)
    service_ids = Enum.map(dates, & &1.service_id)
    service_id_set = MapSet.new(service_ids)
    _routes = load_routes(Path.join([directory, "routes.txt"]), feed)
    trips = load_trips(Path.join([directory, "trips.txt"]), feed, service_id_set)
    trip_ids = Enum.map(trips, & &1.trip_id)
    trip_id_set = MapSet.new(trip_ids)
    stops = load_stops(Path.join([directory, "stops.txt"]), feed)
    load_stop_times(Path.join([directory, "stop_times.txt"]), feed, trip_id_set)
    # load_shapes(Path.join([directory, "shapes.txt"]), feed)
    update_stop_and_shape_points(feed)
    # update_trip_lengths(feed)
    update_trip_times(feed)
    update_stop_route_ids(stops, feed)
  end

  def load_calendar_dates(file, feed) do
    max_date = Date.add(feed.date, 10)

    File.stream!(file)
    |> Stream.drop(1)
    |> Stream.filter(fn row ->
      values =
        String.trim(row)
        |> String.split(",")

      # 20190606
      date =
        Enum.at(values, 1)
        |> String.trim()

      {year, rest} = String.split_at(date, 4)

      {month, day} = String.split_at(rest, 2)

      date = Date.from_iso8601!("#{year}-#{month}-#{day}")

      compare = Date.compare(date, max_date)
      compare == :lt || compare == :eq
    end)
    |> Task.async_stream(
      fn row ->
        values =
          String.trim(row)
          |> String.split(",")

        # 20190606
        date =
          Enum.at(values, 1)
          |> String.trim()

        {year, rest} = String.split_at(date, 4)

        {month, day} = String.split_at(rest, 2)

        params = %{
          service_id: Enum.at(values, 0) |> String.trim(),
          date: Date.from_iso8601!("#{year}-#{month}-#{day}"),
          exception_type: Enum.at(values, 2) |> String.trim(),
          feed_id: feed.id
        }

        CalendarDate.changeset(%CalendarDate{}, params)
        |> Repo.insert!()
      end,
      max_concurrency: 20
    )
    |> Enum.map(fn {:ok, calendar_date} ->
      calendar_date
    end)
  end

  def load_routes(file, feed) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Task.async_stream(
      fn row ->
        values =
          String.trim(row)
          |> String.split(",")

        params = %{
          route_id: Enum.at(values, 0) |> String.trim(),
          route_short_name: Enum.at(values, 2) |> String.trim(),
          route_long_name: Enum.at(values, 3) |> String.trim(),
          route_desc: Enum.at(values, 4) |> String.trim(),
          route_type: Enum.at(values, 5) |> String.trim(),
          route_url: Enum.at(values, 6) |> String.trim(),
          route_color: Enum.at(values, 7) |> String.trim(),
          route_text_color: Enum.at(values, 8) |> String.trim(),
          feed_id: feed.id
        }

        Route.changeset(%Route{}, params)
        |> Repo.insert!()
      end,
      max_concurrency: 20
    )
    |> Enum.map(fn {:ok, route} ->
      route
    end)
  end

  def load_trips(file, feed, service_id_set) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Stream.filter(fn row ->
      values =
        String.trim(row)
        |> String.split(",")

      service_id = Enum.at(values, 1) |> String.trim()

      MapSet.member?(service_id_set, service_id)
    end)
    |> Task.async_stream(
      fn row ->
        values =
          String.trim(row)
          |> String.split(",")

        params = %{
          trip_id: Enum.at(values, 2) |> String.trim(),
          route_id: Enum.at(values, 0) |> String.trim(),
          service_id: Enum.at(values, 1) |> String.trim(),
          trip_headsign: Enum.at(values, 3) |> String.trim(),
          direction_id: Enum.at(values, 4) |> String.trim(),
          block_id: Enum.at(values, 5) |> String.trim(),
          shape_id: Enum.at(values, 6) |> String.trim(),
          feed_id: feed.id
        }

        Trip.changeset(%Trip{}, params)
        |> Repo.insert!()
      end,
      max_concurrency: 20
    )
    |> Enum.map(fn {:ok, trip} ->
      trip
    end)
  end

  def load_stops(file, feed) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Task.async_stream(
      fn row ->
        values =
          String.trim(row)
          |> String.split(",")

        params = %{
          stop_id: Enum.at(values, 0) |> String.trim(),
          stop_code: Enum.at(values, 1) |> String.trim(),
          stop_name: Enum.at(values, 2) |> String.trim(),
          stop_desc: Enum.at(values, 3) |> String.trim(),
          stop_lat: Enum.at(values, 4) |> String.trim(),
          stop_lon: Enum.at(values, 5) |> String.trim(),
          zone_id: Enum.at(values, 6) |> String.trim(),
          stop_url: Enum.at(values, 7) |> String.trim(),
          timepoint: Enum.at(values, 8) |> String.trim(),
          feed_id: feed.id
        }

        Stop.changeset(%Stop{}, params)
        |> Repo.insert!()
      end,
      max_concurrency: 20
    )
    |> Enum.map(fn {:ok, stop} ->
      stop
    end)
  end

  def update_stop_and_shape_points(feed) do
    {:ok, _result} =
      Repo.query(
        """
        update gtfs.stops set geom_point = ST_SetSRID(ST_MakePoint(stop_lon, stop_lat), 4326) where feed_id = $1
        """,
        [feed.id]
      )

    # {:ok, _result} =
    #   Repo.query(
    #     """
    #     update gtfs.shapes set geom_point = ST_SetSRID(ST_MakePoint(shape_pt_lon, shape_pt_lat), 4326) where feed_id = $1
    #     """, [feed.id]
    #   )
  end

  def load_stop_times(file, feed, trip_id_set) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Stream.filter(fn row ->
      values =
        String.trim(row)
        |> String.split(",")

      trip_id = Enum.at(values, 0) |> String.trim()

      MapSet.member?(trip_id_set, trip_id)
    end)
    |> Stream.chunk_every(50)
    |> Task.async_stream(
      fn rows ->
        inserts =
          Enum.map(rows, fn row ->
            values =
              String.trim(row)
              |> String.split(",")

            timepoint =
              "#{Enum.at(values, 8)}"
              |> String.trim()

            params = %{
              trip_id: Enum.at(values, 0) |> String.trim(),
              arrival_time: Enum.at(values, 1) |> String.trim() |> parse_interval(),
              departure_time: Enum.at(values, 2) |> String.trim() |> parse_interval(),
              stop_id: Enum.at(values, 3) |> String.trim(),
              stop_sequence: Enum.at(values, 4) |> String.trim() |> parse_stop_sequence(),
              stop_headsign: Enum.at(values, 5) |> String.trim(),
              pickup_type: Enum.at(values, 6) |> String.trim(),
              drop_off_type: Enum.at(values, 7) |> String.trim(),
              timepoint: timepoint,
              feed_id: feed.id
            }

            cs = StopTime.changeset(%StopTime{}, params)
            true = cs.valid?
            cs.changes
          end)

        Repo.insert_all(StopTime, inserts)
      end,
      max_concurrency: 20
    )
    |> Enum.map(fn {:ok, stop_time} ->
      stop_time
    end)
  end

  def update_stop_route_ids(stops, feed) do
    Enum.each(stops, fn stop ->
      Stop.update_route_ids(stop, feed)
    end)
  end

  def update_trip_times(feed) do
    feed_id = feed.id

    trips =
      from(st in StopTime,
        select: %{
          trip_id: st.trip_id,
          start_time: min(st.arrival_time),
          end_time: max(st.arrival_time),
          time_seconds:
            fragment(
              "extract(epoch from MAX(?)) - extract(epoch from MIN(?))",
              st.arrival_time,
              st.arrival_time
            )
        },
        where: st.feed_id == ^feed_id,
        group_by: st.trip_id
      )
      |> Repo.all()

    Enum.each(trips, fn %{
                          trip_id: trip_id,
                          time_seconds: seconds,
                          start_time: start_time,
                          end_time: end_time
                        } ->
      from(t in Trip, where: t.trip_id == ^trip_id and t.feed_id == ^feed_id)
      |> Repo.update_all(
        set: [length_seconds: round(seconds), start_time: start_time, end_time: end_time]
      )
    end)
  end

  defp parse_interval(interval) do
    [hour, minute, second] =
      String.split(interval, ":")
      |> Enum.map(fn i ->
        {integer, _} = Integer.parse(i)
        integer
      end)

    seconds = hour * 60 * 60 + minute * 60 + second

    days = div(seconds, 24 * 60 * 60)
    seconds = rem(seconds, 24 * 60 * 60)
    %{months: 0, days: days, secs: seconds}
  end

  defp parse_stop_sequence(sequence) do
    {integer, _} = Integer.parse(sequence)
    integer
  end
end
