-- BUSIEST STOPS
select s.stop_id, s.stop_name, COUNT(s.stop_id) from gtfs.stops s
INNER JOIN gtfs.stop_times st on st.stop_id = s.stop_id AND st.feed_id = 1
INNER JOIN gtfs.trips t on t.trip_id = st.trip_id AND t.feed_id = 1
INNER JOIN gtfs.calendar_dates cd on cd.service_id = t.service_id AND cd.feed_id = 1
WHERE cd.date = '2020-03-03' AND s.feed_id = 1
GROUP BY s.stop_id, s.stop_name
order by count(s.stop_id) desc limit 20;

-- STOPS WITH MOST ROUTES
select stop_name, stop_id, route_ids, array_length(route_ids, 1) from gtfs.stops order by array_length(route_ids, 1) DESC;

-- NUMBER OF TRIPS STARTING PER HOUR
select round(extract(epoch from t.start_time) / 3600) || ':00' as hour, COUNT(t.trip_id) from gtfs.trips t
        INNER JOIN gtfs.calendar_dates cd on cd.service_id = t.service_id AND cd.feed_id = 1
        WHERE cd.date = '2020-03-03' AND t.feed_id = 1
        GROUP BY round(extract(epoch from t.start_time) / 3600)
        order by count(t.trip_id) desc;

-- NUMBER OF TRIPS AT A GIVEN TIME
select COUNT(t.trip_id) from gtfs.trips t
INNER JOIN gtfs.calendar_dates cd on cd.service_id = t.service_id AND cd.feed_id = 1
WHERE cd.date = '2020-03-03' AND t.feed_id = 1 AND '17:30:00' BETWEEN t.start_time AND t.end_time
order by count(t.trip_id) desc;
