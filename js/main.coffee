class Waypoint
  constructor: (lat, lng, @title, @description = "", @icon, @shadow) ->
    @location = new google.maps.LatLng lat, lng

  show: (map) ->
    options =
      position: @location
      map: map
      title: @title
      icon: @icon
      shadow: @shadow
    marker = new google.maps.Marker options

class Station extends Waypoint
  constructor: (station) ->
    if station.availableBikes > 0 and station.statusValue == "In Service"
      thisPin = new colorPin pinColors.bikeAvailable
    else
      thisPin = new colorPin pinColors.bikeNotAvailable
    super station.latitude, station.longitude, station.stationName, "", thisPin.pinImage(), thisPin.pinShadow()

class MapData
  @stations = []
  @destinations = []

  fetch: (callback) ->
    @_fetchStations (data) =>
      @stations = data
      @_fetchDestinations (data) =>
        @destinations = data
        callback()

  show: (map) ->
    p.show map for p in @stations
    p.show map for p in @destinations

  _fetchStations: (callback) ->
    $.getJSON 'bikedata.php', (data) ->
      stationPoints = []

      for stationData in data.stationBeanList
        stationPoint = new Station stationData
        stationPoints.push stationPoint

      callback(stationPoints)

  _fetchDestinations: (callback) ->
    $.get 'locations/filmdata.csv', (data) ->
      $.csv.toObjects data, {}, (err, data) ->
        waypoints = []
        for item in data
          itemWaypoint = new Waypoint item.latitude, item.longitude, item.title, item.description, "img/noun_project_16712.png"
          waypoints.push itemWaypoint

        callback(waypoints)

pinColors =
  bikeAvailable: '00FF00'
  bikeNotAvailable: '0000FF'

pins =
  film: "img/noun_project_16712.png"

class colorPin
  constructor: (@color = "FE7569") ->

  pinImage: ->
    new google.maps.MarkerImage("http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + @color,
      new google.maps.Size(21, 34),
      new google.maps.Point(0,0),
      new google.maps.Point(10, 34));

  pinShadow: ->
    new google.maps.MarkerImage("http://chart.apis.google.com/chart?chst=d_map_pin_shadow",
      new google.maps.Size(40, 37),
      new google.maps.Point(0, 0),
      new google.maps.Point(12, 35));

loadWeather = () ->
  feedUrl = "http://weather.yahooapis.com/forecastrss?w=12761716&u=f"
  jsonUrl = "https://ajax.googleapis.com/ajax/services/feed/load?v=1.0&q=" + encodeURIComponent(feedUrl) + "&callback=?"
  $.getJSON jsonUrl, (data) ->
    weatherString = data.responseData.feed.entries[0].contentSnippet
    re = /Current Conditions:\n(.*?)\n/
    match = weatherString.match re
    $("#weather").text match[1]

loadMap = () ->
  mapOptions =
    center: new google.maps.LatLng(40.714346,-74.005966)
    zoom: 12
    mapTypeId: google.maps.MapTypeId.ROADMAP
  google.maps.visualRefresh = true
  map = new google.maps.Map document.getElementById("map_canvas"), mapOptions

class Navigator
  constructor: (@map, @stations, @destinations) ->
    @directionsService = new google.maps.DirectionsService()
    @geocoder = new google.maps.Geocoder();

  _directions: (options, callback) ->
    @directionsService.route options, (result, status) ->
      if status == google.maps.DirectionStatus.OK
        callback result

  _distance: (LatLng1, LatLng2) ->
    return math.sqrt math.pow(LatLng1.lat() - LatLng2.lat(), 2) + math.pow(LatLng1.lng() - LatLng2.lng(), 2)

  _sortArrayByDistance: (array) ->
    compare = (a,b) ->
      if a.distance < b.distance
        return -1
      if a.distance > b.distance
        return 1
      return 0
    array.sort compare
    return array

  geocode: (address, callback) ->
    @geocoder.geocode {address: address}, (results, status) ->
      if status == google.maps.GeocoderStatus.OK
        callback(results.geometry.location)

  nearestStation: (location) ->
    minDistance = Infinity
    nearest = null
    for station in @stations
      distance = @_distance(station.location, location)
      if distance < minDistance
        nearest = station
    return nearest

  calculate: (start, end, destinationCount, callback) ->
    # Geocode start and end points
    @geocode start, (location) ->
      startLoc = location
      @geocode end, (location) ->
        endLoc = location

        # Find nearest available bike stations to start and end points
        startStation = nearestStation(startLoc)
        endStation = nearestStation(endLoc)

        # Find direct biking route
        options =
          origin: startStation.location
          destination: endStation.location
          travelMode: google.maps.TravelMode.BIKING
        @_directions options, (result) ->
          console.log result

        # Search for waypoints along route

  print: () ->
    $.getJSON 'http://maps.googleapis.com/maps/api/directions/json?origin=Museum+Of+The+Moving+Image&destination=34+Ludlow+Street,NY&sensor=false&mode=bicycling', (data) ->
      leg_end = []
      
      #start address
      departure_string = data.routes[0].legs[0].start_address #get complete departure address
      departure = departure_string.split ","; #split address at commas into array
      start_wrap = '<div class="departure"><b>' + departure[0] + '</b><br/>' #name of place is bolded
      for item in departure[1..] #rest of address
        start_wrap += item + ',' #add ,'s back to address
      start_wrap = start_wrap.substring 0,start_wrap.lastIndexOf(',') #remove the trailing comma
      start_wrap += '<br/><br/></div>' #close the address div
      $(start_wrap).appendTo 'div.directions' #begin directions formatting, start location
      
      #print total travel time
        
      #print directions
      for leg,i in data.routes[0].legs
        leg_end.push leg.end_address
        leg_wrap = '<ol class="directions">'
        $(leg_wrap).appendTo 'div.directions'
        
        #print each direction step
        for step in leg.steps
          step_wrap = "<li>" + step.html_instructions + '<br/><div class="dist-time">' + step.distance.text + " - about " + step.duration.text + "</div></li>";
          $(step_wrap).appendTo 'ol.directions'
        
        #print leg time/distance
        leg_wrap = '<div class="dist-time-lg">' + leg.distance.text + " - about " + leg.duration.text + "</div><br/>"
        $(leg_wrap).appendTo 'div.directions'
        
        #end address
        arrival_string = leg.end_address #get complete address
        arrival = arrival_string.split ","; #split address at commas
        end_wrap = '</ol><div class="arrival"><b>' + arrival[i] + '</b><br/>' #name of place is bolded
        for item in arrival[1..] #rest of address
          end_wrap += item + ',' #add commas back into address
        end_wrap = end_wrap.substring 0,end_wrap.lastIndexOf(',') #remove the trailing comma
        end_wrap += '<br/><br/></div>' #close div
        $(end_wrap).appendTo 'div.directions' #write

class Interface
  constructor: (@map, @fetcher, @nav) ->


initialize = () ->
  loadWeather()
  map = loadMap()
  fetcher = new MapData()
  fetcher.fetch () ->
    fetcher.show map
    nav = new Navigator map, fetcher.stations, fetcher.destinations
    ui = new Interface map, fetcher, nav
    nav.print()

$(document).ready () =>
  initialize()