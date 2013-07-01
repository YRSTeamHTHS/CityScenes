class Waypoint
  constructor: (lat, lng, @title, @description = "", @icon, @shadow) ->
    @location = new google.maps.LatLng lat, lng

  show: (map) ->
    options =
      position: @location
      map: map.gmap
      title: @title
      icon: @icon
      shadow: @shadow
    marker = new google.maps.Marker options
    return marker

class Station extends Waypoint
  constructor: (station) ->
    if station.availableBikes > 0 and station.statusValue == "In Service"
      thisMarker = markers.circle("green")
      @available = true
    else
      thisMarker = markers.circle("red")
      @available = false
    super station.latitude, station.longitude, station.stationName, "", thisMarker

class DestinationPoint extends Waypoint
  constructor: (@type, item) ->
    super item.latitude, item.longitude, item.title, item.description, markers.goldStar

class DataFetcher
  @stations = []
  @destinations = []

  fetch: (callback) ->
    @_fetchStations (err, data) =>
      @stations = data
      @_fetchDestinations (err, destinations, destinationTypes) =>
        @destinations = destinations
        @destinationTypes = destinationTypes
        callback null, {stations: @stations, destinations: @destinations, destinationTypes: @destinationTypes}

  show: (map) ->
    stationArray = (p.show map for p in @stations)
    #stationClusterer = new MarkerClusterer map.gmap, stationArray

    destinationArray = (p.show map for p in @destinations)
    destinationClusterer = new MarkerClusterer map.gmap, destinationArray, {
      minimumClusterSize: 3
    }


  _fetchStations: (callback) ->
    $.getJSON 'bikedata/index.php', (data) ->
      stationPoints = []

      for stationData in data.stationBeanList
        stationPoint = new Station stationData
        stationPoints.push stationPoint

      callback null, stationPoints

  _fetchDestinations: (callback) ->
    $.getJSON 'locations/index.php', (data) =>
      async.concat data, @_fetchDestinationFile, (err, results) ->
        callback err, results, (i[0..-5] for i in data)

  _fetchDestinationFile: (filename, callback) ->
    type = filename[0..-5]
    $.get 'locations/' + filename, (data) =>
      $.csv.toObjects data, {}, (err, data) =>
        waypoints = []
        for item in data
          itemWaypoint = new DestinationPoint type, item
          waypoints.push itemWaypoint
        callback null, waypoints

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
    scale: 0.07,
    strokeColor: "gold",
    strokeWeight: 3
  }

loadWeather = () ->
  $.get 'weatherdata/index.php', (data) ->
    re = /(.*?)\n([0-9]{2}?)/
    match = data.match re
    $("#weather").text match[1]
    #change weather icon
    code = parseInt match[2]
    
    if ($.inArray(code,[31,32,33,34,36,24,25]) !=-1)
        $(".weather-icon").attr('id','ico-sun');
    else if ($.inArray(code,[1,2,5,6,8,9,10,11,12,17,18,35,40]) !=-1) #rainy
      $(".weather-icon").attr('id','ico-rain');
    else if ($.inArray(code,[3,4,37,38,39,45,47]) !=-1)
      $(".weather-icon").attr('id','ico-thunder');
    else if ($.inArray(code,[13,7,14,15,16,41,42,43,46]) !=-1)
      $(".weather-icon").attr('id','ico-snow');
    else $(".weather-icon").attr('id','ico-cloud');

class Navigator
  constructor: (@map, @stations, @destinations, @destinationTypes) ->
    #@directionsService = new google.maps.DirectionsService()
    @geocoder = new google.maps.Geocoder()
    @directionsDisplays = []
    for i in [0,1,2]
      options = {}
      if i in [0,2]
        options.preserveViewport = true
      @directionsDisplays[i] = new google.maps.DirectionsRenderer(options)
      @directionsDisplays[i].setMap @map.gmap

  _directions: (options, callback) ->
    directionsService = new google.maps.DirectionsService()
    directionsService.route options, (result, status) ->
      if status == google.maps.DirectionsStatus.OK
        console.log "Direction Result", result
        callback null, result

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
        callback null, results[0].geometry.location

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

  _nearestDestinations: (path, count, types) ->
    # Filter available list of destinations by desired type
    availableDestinations = []
    for destination in @destinations
      if destination.type in types
        availableDestinations.push destination

    console.log "availableDestinations", availableDestinations

    all = []
    for point in path
      a = [point.jb, point.kb]
      list = []
      for destination in availableDestinations
        list.push [@_distance_raw(a, @_LatLng_to_raw(destination.location)), destination]
      list = @_sort_array_by_distance(list)[0..count]
      all = all.concat list
    sortedDestinations = (i[1] for i in @_sort_array_by_distance(all))

    console.log "sortedDestinations", sortedDestinations

    uniqueDestinations = []
    for destination in sortedDestinations
      if destination not in uniqueDestinations and uniqueDestinations.length < count
        uniqueDestinations.push destination

    console.log "uniqueDestinations", uniqueDestinations

    return uniqueDestinations

  _destinationsToDirectionsWaypoints: (destinations) ->
    return ({location: i.location} for i in destinations)

  calculate: (start, end, destinationCount, userDestinationTypes, callback) ->
    # Geocode start and end points
    @geocode start, (err, location) =>
      startLoc = location
      @geocode end, (err, location) =>
        endLoc = location

        # Find nearest available bike stations to start and end points
        startStation = @nearestStation(startLoc)
        endStation = @nearestStation(endLoc)

        # Find direct biking route
        options =
          origin: startStation.location
          destination: endStation.location
          travelMode: google.maps.TravelMode.BICYCLING
        @_directions options, (err, result) =>
          # Search for waypoints along route
          destinations = @_nearestDestinations(result.routes[0].overview_path, destinationCount, userDestinationTypes)
          console.log "Destinations", destinations
          DirectionsWaypoints = @_destinationsToDirectionsWaypoints(destinations)
          console.log "DirectionsWaypoints", DirectionsWaypoints

          options = []

          # Navigate to the start bike station
          options.push {
            origin: startLoc
            destination: startStation.location
            travelMode: google.maps.TravelMode.WALKING
          }

          # Navigate through the waypoints
          options.push {
            origin: startStation.location
            destination: endStation.location
            travelMode: google.maps.TravelMode.BICYCLING
            optimizeWaypoints: true
            waypoints: DirectionsWaypoints
          }

          # Navigate from the end bike station
          options.push {
            origin: endStation.location
            destination: endLoc
            travelMode: google.maps.TravelMode.WALKING
          }

          console.log "Directions Options", options

          async.map options, @_directions, (err, results) =>
            console.log "Directions Results", results
            @_print results, startStation, destinations, endStation
            callback null, result

  _print: (results, startStation, destinations, endStation) ->
    # (Results is a array with three result elements: [walking, biking, walking])

    # Clear old directions
    $(".directions").html("")

    # Merge waypoint titles
    titles = []
    titles.push ["Start", startStation.title]
    midTitles = [startStation.title].concat((i.title for i in destinations))
    midTitles.push(endStation.title)
    titles.push midTitles
    titles.push [endStation.title, "End"]

    total_time = 0
    for i in [0,1,2]
      total_time += @_routeTime(results[i])

    @_printTime(total_time)

    for i in [0,1,2]
      @_printRoute(results[i], titles[i])
      # Show route on map
      @directionsDisplays[i].setDirections results[i]

  _routeTime: (result) ->
    #print total travel time
    total_time = 0
    for leg in result.routes[0].legs
      total_time += leg.duration.value
    return total_time

  _printTime: (total_time) ->
    minutes = Math.ceil(total_time / 60)
    hours = Math.floor(minutes/60)
    minutes = minutes%60
    if hours > 0
      time_wrap = '<div class="dist-time-total">Total Travel Time: '+hours+' hours, '+minutes+' minutes'+'</div><br/>'
    else
      time_wrap = '<div class="dist-time-total">Total Travel Time: '+minutes+' minutes'+'</div><br/>'
    $(time_wrap).appendTo 'div.directions' #print total time

  _printRoute: (result, titles) ->
    #$.getJSON 'http://maps.googleapis.com/maps/api/directions/json?origin=Museum+Of+The+Moving+Image&destination=34+Ludlow+Street,NY&waypoints=30+Ludlow+St,NY|100+Canal+St,NY&sensor=false&mode=bicycling', (data) ->

    #console.log "Printing result", result
    #console.log "Printing titles", titles

    leg_end = []
    waypoint_order = result.routes[0].waypoint_order

    #start address
    
    departure_string = result.routes[0].legs[0].start_address #get complete departure address
    departure = departure_string.split ","; #split address at commas into array
    start_wrap = '<hr/><div class="departure"><b>' + titles[0] + '</b><br/>' + departure[0] + '<br/>' #name of place is bolded
    for item in departure[1..] #rest of address
      start_wrap += item + ',' #add ,'s back to address
    start_wrap = start_wrap.substring 0,start_wrap.lastIndexOf(',') #remove the trailing comma
    start_wrap += '<br/><br/></div>' #close the address div
    $(start_wrap).appendTo 'div.directions' #begin directions formatting, start location
    
    $(".directions").attr('id',result.routes[0].legs[0].travel_mode);
    
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
        end_wrap = '</ol><div class="waypoint"><b>' + titles[waypoint_order[i]+1] + '</b><br/>' + arrival[0] + '<br/>' #name of place is bolded
      else
        end_wrap = '</ol><div class="arrival"><b>' + titles[titles.length-1] + '</b><br/>' + arrival[0] + '<br/>' #name of place is bolded
      for item in arrival[1..] #rest of address
        end_wrap += item + ',' #add commas back into address
      end_wrap = end_wrap.substring 0,end_wrap.lastIndexOf(',') #remove the trailing comma
      end_wrap += '<br/><br/></div>' #close div
      $(end_wrap).appendTo 'div.directions' #write
        
class Display
  constructor: () ->
    @loading_modal = $("#loading_modal")
    @loading_modal.modal()

  _initControls: () ->
    # Show available destination types
    $typeElem = $('<label class="checkbox type_checkbox"><input type="checkbox" checked><span class="type_label"></span></label>')
    for type in @destinationTypes
      $elem = $typeElem.clone()
      $elem.find('.type_label').text(type)
      $elem.find('input').attr('name', type)
      $elem.appendTo('#destination_types')

    $("#directions_form").submit (e) =>
      @loading_modal.modal("show")
      e.preventDefault()
      start = $("#start").val()
      end = $("#end").val()
      stops = $("#stops").val()

      # Load desired destination types from form
      types = []
      $("#destination_types input").each () ->
        if $(this).is(":checked")
          types.push $(this).attr("name")

      @nav.calculate start, end, stops, types, (err, data) =>
        console.log data
        @loading_modal.modal("hide")
      return false

  load: () ->
    loadWeather()
    @map = new Map()
    @map.load()
    @fetcher = new DataFetcher()
    @fetcher.fetch (err, result) =>
      @fetcher.show @map
      @destinationTypes = result.destinationTypes
      console.log "destinationTypes", @destinationTypes
      @nav = new Navigator @map, result.stations, result.destinations, result.destinationTypes
      @_initControls()
      @loading_modal.modal("hide")

class Map
  load: () ->
    mapOptions =
      center: new google.maps.LatLng(40.7444123,-73.9935986) # Center on Times Square
      zoom: 14
      mapTypeId: google.maps.MapTypeId.ROADMAP
    google.maps.visualRefresh = true
    @gmap = new google.maps.Map document.getElementById("map_canvas"), mapOptions
    bikeLayer = new google.maps.BicyclingLayer()
    bikeLayer.setMap(@gmap)

initialize = () ->
  disp = new Display()
  disp.load()

$(document).ready () =>
  initialize()