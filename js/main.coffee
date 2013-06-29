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
  pinAvailable = new pin pinColors.bikeAvailable
  pinNotAvailable = new pin pinColors.bikeNotAvailable
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

class pin
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
  map = new google.maps.Map document.getElementById("map-canvas"), mapOptions

initialize = () ->
  loadWeather()

  map = loadMap()
  plotFilms map
  plotBikes map

$(document).ready () =>
  initialize()