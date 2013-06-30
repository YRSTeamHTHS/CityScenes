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

  _directions: (options, callback) ->
    @directionsService.route options, (result, status) ->
      if status == google.maps.DirectionStatus.OK
        callback result

  _distance: (LatLng1, LatLng2) ->
    return math.sqrt math.pow(LatLng1.lat() - LatLng2.lat(), 2) + math.pow(LatLng1.lng() - LatLng2.lng(), 2)

  calculate: (options, callback) ->
    # Find nearest available bike stations to start and end points
    for station in @stations
      continue

    # Find direct biking route
    options =
      origin: options.start
      destination: options.end
      travelMode: google.maps.TravelMode.BIKING
    @_directions options, (result) ->
      console.log result

    # Search for waypoints along route

    $.getJSON 'http://maps.googleapis.com/maps/api/directions/json?origin=Museum+Of+The+Moving+Image&destination=34+Ludlow+Street,NY&sensor=false&mode=bicycling', (data) ->
      leg_end = []
      departure = data.routes[0].legs[0].start_address
      start_wrap = '<div class="departure">' + departure.replace(',','<br/>') + '<br/><br/></div>'
      $(start_wrap).appendTo 'div.directions' #begin directions formatting, start location

      for leg in data.routes[0].legs
        leg_end.push leg.end_address
        leg_wrap = '<ol class="directions">'
        $(leg_wrap).appendTo 'div.directions'

        for step in leg.steps
          step_wrap = "<li>" + step.html_instructions + '<br/><div class="dist-time" style="text-align:right">' + step.distance.text + " - about " + step.duration.text + "</div></li>";
          $(step_wrap).appendTo 'ol.directions'
        
      leg_wrap = '</ol><div class="arrival">' + leg.end_address.replace(',','<br/>') + '</div>'
      $(leg_wrap).appendTo 'div.directions'

  navigate: (callback) ->


initialize = () ->
  loadWeather()
  map = loadMap()
  fetcher = new MapData()
  fetcher.fetch () ->
    fetcher.show map
    nav = new Navigator map, fetcher.stations, fetcher.destinations

$(document).ready () =>
  initialize()