plotFilms = (map) ->
  $.get 'filmdata.csv', (data) ->
    $.csv.toObjects data, {}, (err, data) ->
      for item in data
        marker = new google.maps.Marker {
          position: new google.maps.LatLng(item.LATITUDE,item.LONGITUDE),
          map: map,
          title: item.Film
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
  feed = new google.feeds.Feed "http://weather.yahooapis.com/forecastrss?w=12761716&u=f"
  feed.load (result) ->
    if !result.error
      console.log result.feed.entries

initialize = () ->
  # Load weather
  #google.load "feeds", "1"
  #google.setOnLoadCallback loadWeather

  mapOptions =
    center: new google.maps.LatLng(40.714346,-74.005966)
    zoom: 12
    mapTypeId: google.maps.MapTypeId.ROADMAP
  google.maps.visualRefresh = true
  map = new google.maps.Map document.getElementById("map-canvas"), mapOptions

  plotFilms map
  plotBikes map

$(document).ready () =>
  initialize()