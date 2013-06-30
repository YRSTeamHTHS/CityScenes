plotFilms = (map) ->
  $.get 'locations/filmdata.csv', (data) ->
    $.csv.toObjects data, {}, (err, data) ->
      for item in data
        marker = new google.maps.Marker {
          position: new google.maps.LatLng(item.LATITUDE,item.LONGITUDE)
          map: map
          title: item.Film
          icon: pins.film
        }

plotBikes = (map) ->
  pinAvailable = new colorPin pinColors.bikeAvailable
  pinNotAvailable = new colorPin pinColors.bikeNotAvailable
  $.getJSON 'bikedata.php', (data) ->
    for station in data.stationBeanList
      #console.log station
      if station.availableBikes > 0 and station.statusValue == "In Service"
        thisPin = pinAvailable
      else
        thisPin = pinNotAvailable
      marker = new google.maps.Marker {
        position: new google.maps.LatLng(station.latitude, station.longitude)
        map: map
        title: station.stationName
        icon: thisPin.pinImage()
        shadow: thisPin.pinShadow()
      }

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
  navigate: () ->
    $.getJSON 'http://maps.googleapis.com/maps/api/directions/json?origin=Museum+Of+The+Moving+Image&destination=34+Ludlow+Street,NY&sensor=false&mode=bicycling', (data) ->
      leg_end = []
      start_wrap = '<span>' + data.routes[0].legs[0].start_address + '<br /><br /></span>'
      $(start_wrap).appendTo 'div.directions' #begin directions formatting, start location

      for leg in data.routes[0].legs
        leg_end.push leg.end_address
        leg_wrap = '<ol class="directions">'
        $(leg_wrap).appendTo 'div.directions'

        for step in leg.steps
          step_wrap = "<li>" + step.html_instructions + '<br/><div class="distance" style="text-align:right">' + step.distance.text + " - about " + step.duration.text + "</div></li>";
          $(step_wrap).appendTo 'ol.directions'

          leg_wrap = '<br /></ol><span>' + leg.end_address + '</span>'
          $(leg_wrap).appendTo 'div.directions'

initialize = () ->
  loadWeather()

  map = loadMap()
  plotFilms map
  plotBikes map

  nav = new Navigator
  nav.navigate()

$(document).ready () =>
  initialize()