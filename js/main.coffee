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
      thisMarker = markers.circle("green")
      @available = true
    else
      thisMarker = markers.circle("red")
      @available = false
    super station.latitude, station.longitude, station.stationName, "", thisMarker

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
          itemWaypoint = new Waypoint item.latitude, item.longitude, item.title, item.description, markers.goldStar
          waypoints.push itemWaypoint

        callback(waypoints)

pinColors =
  bikeAvailable: '00FF00'
  bikeNotAvailable: '0000FF'

markers =
  film: "img/noun_project_16712.png"
  circle: (color) ->
    return {
      path: google.maps.SymbolPath.CIRCLE
      fillColor: color
      fillOpacity: 0.8
      scale: 5
      strokeWeight: 3
      strokeColor: "white"
    }
  goldStar: {
    path: 'M 125,5 155,90 245,90 175,145 200,230 125,180 50,230 75,145 5,90 95,90 z',
    fillColor: "yellow",
    fillOpacity: 0.8,
    scale: 0.1,
    strokeColor: "gold",
    strokeWeight: 3
  }

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
  bikeLayer = new google.maps.BicyclingLayer()
  bikeLayer.setMap(map)
  return map

class Navigator
  constructor: (@map, @stations, @destinations) ->
    @directionsService = new google.maps.DirectionsService()
    @geocoder = new google.maps.Geocoder()
    @directionsDisplay = new google.maps.DirectionsRenderer()
    @directionsDisplay.setMap map

  _directions: (options, callback) ->
    @directionsService.route options, (result, status) ->
      if status == google.maps.DirectionsStatus.OK
        callback result

  _distance: (LatLng1, LatLng2) ->
    return Math.pow(LatLng1.lat() - LatLng2.lat(), 2) + Math.pow(LatLng1.lng() - LatLng2.lng(), 2)

  _distance_raw: (a, b) ->
    return Math.pow(a[0] - b[0], 2) + Math.pow(a[1] - b[1], 2)

  _LatLng_to_raw: (LatLng) ->
    return [LatLng.lat(), LatLng.lng()]

  _sort_array_by_distance: (array) ->
    compare = (a,b) ->
      if a[0] < b[0]
        return -1
      if a[0] > b[0]
        return 1
      return 0
    array.sort compare
    return array

  geocode: (address, callback) ->
    @geocoder.geocode {address: address}, (results, status) ->
      if status == google.maps.GeocoderStatus.OK
        callback(results[0].geometry.location)

  nearestStation: (location) ->
    minDistance = Infinity
    nearest = null
    for station in @stations
      if station.available
        distance = @_distance(station.location, location)
        if distance < minDistance
          nearest = station
          minDistance = distance
    return nearest

  _nearestDestinations: (path, count) ->
    all = []
    for point in path
      a = [point.jb, point.kb]
      list = []
      for destination in @destinations
        list.push [@_distance_raw(a, @_LatLng_to_raw(destination.location)), destination]
      list = @_sort_array_by_distance(list)[0..count]
      all = all.concat list
    all = @_sort_array_by_distance(all)[0..count]
    DirectionsWaypoints = ({location: i[1].location} for i in all)
    console.log DirectionsWaypoints
    return DirectionsWaypoints

  calculate: (start, end, destinationCount, callback) ->
    # Geocode start and end points
    @geocode start, (location) =>
      startLoc = location
      @geocode end, (location) =>
        endLoc = location

        # Find nearest available bike stations to start and end points
        startStation = @nearestStation(startLoc)
        endStation = @nearestStation(endLoc)

        # Find direct biking route
        options =
          origin: startStation.location
          destination: endStation.location
          travelMode: google.maps.TravelMode.BICYCLING
        @_directions options, (result) =>
          # Search for waypoints along route
          DirectionsWaypoints = @_nearestDestinations(result.routes[0].overview_path, destinationCount)

          # Navigate through the waypoints
          options =
            origin: startStation.location
            destination: endStation.location
            travelMode: google.maps.TravelMode.BICYCLING
            optimizeWaypoints: true
            waypoints: DirectionsWaypoints
          @_directions options, (result) =>
            @_print result
            callback result

  _print: (result) ->
    #$.getJSON 'http://maps.googleapis.com/maps/api/directions/json?origin=Museum+Of+The+Moving+Image&destination=34+Ludlow+Street,NY&waypoints=30+Ludlow+St,NY|100+Canal+St,NY&sensor=false&mode=bicycling', (data) ->
    #http://maps.googleapis.com/maps/api/directions/json?origin=Museum+Of+The+Moving+Image&destination=34+Ludlow+Street,NY&sensor=false&mode=bicycling
    console.log result

    # Show route on map
    @directionsDisplay.setDirections result

    # Clear old directions
    $(".directions").html("")

    leg_end = []
    
    #print total travel time
    total_time = 0
    for leg in result.routes[0].legs
      total_time += leg.duration.value
    minutes = Math.ceil(total_time / 60)
    hours = Math.floor(minutes/60)
    minutes = minutes%60
    if hours > 0
      time_wrap = '<div class="dist-time-total">Total Travel Time: '+hours+' hours'+minutes+' minutes'+'</div><br/>'
    else
      time_wrap = '<div class="dist-time-total">Total Travel Time: '+minutes+' minutes'+'</div><br/>'
    $(time_wrap).appendTo 'div.directions' #print total time
      
    #start address
    departure_string = result.routes[0].legs[0].start_address #get complete departure address
    departure = departure_string.split ","; #split address at commas into array
    start_wrap = '<div class="departure"><b>' + departure[0] + '</b><br/>' #name of place is bolded
    for item in departure[1..] #rest of address
      start_wrap += item + ',' #add ,'s back to address
    start_wrap = start_wrap.substring 0,start_wrap.lastIndexOf(',') #remove the trailing comma
    start_wrap += '<br/><br/></div>' #close the address div
    $(start_wrap).appendTo 'div.directions' #begin directions formatting, start location
        
    #print directions
    for leg,i in result.routes[0].legs
      leg_end.push leg.end_address
      leg_wrap = '<ol class="directions">'
      $(leg_wrap).appendTo 'div.directions'
        
      #print each direction step
      for step in leg.steps
        instr_text = step.instructions.replace('<div>','<br/><span>') #replace opening div tag with br and span
        instr_text = step.instructions.replace('</div>','</span>') #replace closing div tag with span
        step_wrap = "<li>" + instr_text + '<br/><div class="dist-time">' + step.distance.text + " - about " + step.duration.text + "</div></li>";
        $(step_wrap).appendTo 'ol.directions:last-child'
        
      #print leg time/distance
      leg_wrap = '<div class="dist-time-lg">' + leg.distance.text + " - about " + leg.duration.text + "</div><hr><br/>"
      $(leg_wrap).appendTo 'div.directions'
        
      #end address
      arrival_string = leg.end_address #get complete address
      arrival = arrival_string.split ","; #split address at commas
      if i != result.routes[0].legs.length-1 #if a waypoint
        end_wrap = '</ol><div class="waypoint"><b>' + arrival[0] + '</b><br/>' #name of place is bolded
      else
        end_wrap = '</ol><div class="arrival"><b>' + arrival[0] + '</b><br/>' #name of place is bolded
      for item in arrival[1..] #rest of address
        end_wrap += item + ',' #add commas back into address
      end_wrap = end_wrap.substring 0,end_wrap.lastIndexOf(',') #remove the trailing comma
      end_wrap += '<br/><br/></div>' #close div
      $(end_wrap).appendTo 'div.directions' #write
        
class Interface
  constructor: (@map, @fetcher, @nav) ->
    $("#directions_form").submit (e) ->
      e.preventDefault()
      start = $("#start").val()
      end = $("#end").val()
      stops = $("#stops").val()
      nav.calculate start, end, stops, (data) ->
        console.log data
      return false

initialize = () ->
  loadWeather()
  map = loadMap()
  fetcher = new MapData()
  fetcher.fetch () ->
    fetcher.show map
    nav = new Navigator map, fetcher.stations, fetcher.destinations
    ui = new Interface map, fetcher, nav

$(document).ready () =>
  initialize()