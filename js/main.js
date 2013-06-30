// Generated by CoffeeScript 1.4.0
(function() {
  var Interface, MapData, Navigator, Station, Waypoint, colorPin, initialize, loadMap, loadWeather, pinColors, pins,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    _this = this;

  Waypoint = (function() {

    function Waypoint(lat, lng, title, description, icon, shadow) {
      this.title = title;
      this.description = description != null ? description : "";
      this.icon = icon;
      this.shadow = shadow;
      this.location = new google.maps.LatLng(lat, lng);
    }

    Waypoint.prototype.show = function(map) {
      var marker, options;
      options = {
        position: this.location,
        map: map,
        title: this.title,
        icon: this.icon,
        shadow: this.shadow
      };
      return marker = new google.maps.Marker(options);
    };

    return Waypoint;

  })();

  Station = (function(_super) {

    __extends(Station, _super);

    function Station(station) {
      var thisPin;
      if (station.availableBikes > 0 && station.statusValue === "In Service") {
        thisPin = new colorPin(pinColors.bikeAvailable);
      } else {
        thisPin = new colorPin(pinColors.bikeNotAvailable);
      }
      Station.__super__.constructor.call(this, station.latitude, station.longitude, station.stationName, "", thisPin.pinImage(), thisPin.pinShadow());
    }

    return Station;

  })(Waypoint);

  MapData = (function() {

    function MapData() {}

    MapData.stations = [];

    MapData.destinations = [];

    MapData.prototype.fetch = function(callback) {
      var _this = this;
      return this._fetchStations(function(data) {
        _this.stations = data;
        return _this._fetchDestinations(function(data) {
          _this.destinations = data;
          return callback();
        });
      });
    };

    MapData.prototype.show = function(map) {
      var p, _i, _j, _len, _len1, _ref, _ref1, _results;
      _ref = this.stations;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        p.show(map);
      }
      _ref1 = this.destinations;
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        p = _ref1[_j];
        _results.push(p.show(map));
      }
      return _results;
    };

    MapData.prototype._fetchStations = function(callback) {
      return $.getJSON('bikedata.php', function(data) {
        var stationData, stationPoint, stationPoints, _i, _len, _ref;
        stationPoints = [];
        _ref = data.stationBeanList;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          stationData = _ref[_i];
          stationPoint = new Station(stationData);
          stationPoints.push(stationPoint);
        }
        return callback(stationPoints);
      });
    };

    MapData.prototype._fetchDestinations = function(callback) {
      return $.get('locations/filmdata.csv', function(data) {
        return $.csv.toObjects(data, {}, function(err, data) {
          var item, itemWaypoint, waypoints, _i, _len;
          waypoints = [];
          for (_i = 0, _len = data.length; _i < _len; _i++) {
            item = data[_i];
            itemWaypoint = new Waypoint(item.latitude, item.longitude, item.title, item.description, "img/noun_project_16712.png");
            waypoints.push(itemWaypoint);
          }
          return callback(waypoints);
        });
      });
    };

    return MapData;

  })();

  pinColors = {
    bikeAvailable: '00FF00',
    bikeNotAvailable: '0000FF'
  };

  pins = {
    film: "img/noun_project_16712.png"
  };

  colorPin = (function() {

    function colorPin(color) {
      this.color = color != null ? color : "FE7569";
    }

    colorPin.prototype.pinImage = function() {
      return new google.maps.MarkerImage("http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + this.color, new google.maps.Size(21, 34), new google.maps.Point(0, 0), new google.maps.Point(10, 34));
    };

    colorPin.prototype.pinShadow = function() {
      return new google.maps.MarkerImage("http://chart.apis.google.com/chart?chst=d_map_pin_shadow", new google.maps.Size(40, 37), new google.maps.Point(0, 0), new google.maps.Point(12, 35));
    };

    return colorPin;

  })();

  loadWeather = function() {
    var feedUrl, jsonUrl;
    feedUrl = "http://weather.yahooapis.com/forecastrss?w=12761716&u=f";
    jsonUrl = "https://ajax.googleapis.com/ajax/services/feed/load?v=1.0&q=" + encodeURIComponent(feedUrl) + "&callback=?";
    return $.getJSON(jsonUrl, function(data) {
      var match, re, weatherString;
      weatherString = data.responseData.feed.entries[0].contentSnippet;
      re = /Current Conditions:\n(.*?)\n/;
      match = weatherString.match(re);
      return $("#weather").text(match[1]);
    });
  };

  loadMap = function() {
    var map, mapOptions;
    mapOptions = {
      center: new google.maps.LatLng(40.714346, -74.005966),
      zoom: 12,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    google.maps.visualRefresh = true;
    return map = new google.maps.Map(document.getElementById("map_canvas"), mapOptions);
  };

  Navigator = (function() {

    function Navigator(map, stations, destinations) {
      this.map = map;
      this.stations = stations;
      this.destinations = destinations;
      this.directionsService = new google.maps.DirectionsService();
      this.geocoder = new google.maps.Geocoder();
    }

    Navigator.prototype._directions = function(options, callback) {
      return this.directionsService.route(options, function(result, status) {
        if (status === google.maps.DirectionStatus.OK) {
          return callback(result);
        }
      });
    };

    Navigator.prototype._distance = function(LatLng1, LatLng2) {
      return math.sqrt(math.pow(LatLng1.lat() - LatLng2.lat(), 2) + math.pow(LatLng1.lng() - LatLng2.lng(), 2));
    };

    Navigator.prototype._sortArrayByDistance = function(array) {
      var compare;
      compare = function(a, b) {
        if (a.distance < b.distance) {
          return -1;
        }
        if (a.distance > b.distance) {
          return 1;
        }
        return 0;
      };
      array.sort(compare);
      return array;
    };

    Navigator.prototype.geocode = function(address, callback) {
      return this.geocoder.geocode({
        address: address
      }, function(results, status) {
        if (status === google.maps.GeocoderStatus.OK) {
          return callback(results.geometry.location);
        }
      });
    };

    Navigator.prototype.nearestStation = function(location) {
      var distance, minDistance, nearest, station, _i, _len, _ref;
      minDistance = Infinity;
      nearest = null;
      _ref = this.stations;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        station = _ref[_i];
        distance = this._distance(station.location, location);
        if (distance < minDistance) {
          nearest = station;
        }
      }
      return nearest;
    };

    Navigator.prototype.calculate = function(start, end, destinationCount, callback) {
      return this.geocode(start, function(location) {
        var startLoc;
        startLoc = location;
        return this.geocode(end, function(location) {
          var endLoc, endStation, options, startStation;
          endLoc = location;
          startStation = nearestStation(startLoc);
          endStation = nearestStation(endLoc);
          options = {
            origin: startStation.location,
            destination: endStation.location,
            travelMode: google.maps.TravelMode.BIKING
          };
          return this._directions(options, function(result) {
            return console.log(result);
          });
        });
      });
    };

    Navigator.prototype.print = function() {
      return $.getJSON('http://maps.googleapis.com/maps/api/directions/json?origin=Museum+Of+The+Moving+Image&destination=34+Ludlow+Street,NY&sensor=false&mode=bicycling', function(data) {
        var departure, leg, leg_end, leg_wrap, start_wrap, step, step_wrap, _i, _j, _len, _len1, _ref, _ref1;
        leg_end = [];
        departure = data.routes[0].legs[0].start_address;
        start_wrap = '<div class="departure">' + departure.replace(',', '<br/>') + '<br/><br/></div>';
        $(start_wrap).appendTo('div.directions');
        _ref = data.routes[0].legs;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          leg = _ref[_i];
          leg_end.push(leg.end_address);
          leg_wrap = '<ol class="directions">';
          $(leg_wrap).appendTo('div.directions');
          _ref1 = leg.steps;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            step = _ref1[_j];
            step_wrap = "<li>" + step.html_instructions + '<br/><div class="dist-time" style="text-align:right">' + step.distance.text + " - about " + step.duration.text + "</div></li>";
            $(step_wrap).appendTo('ol.directions');
          }
        }
        leg_wrap = '</ol><div class="arrival">' + leg.end_address.replace(',', '<br/>') + '</div>';
        return $(leg_wrap).appendTo('div.directions');
      });
    };

    return Navigator;

  })();

  Interface = (function() {

    function Interface(map, fetcher, nav) {
      this.map = map;
      this.fetcher = fetcher;
      this.nav = nav;
    }

    return Interface;

  })();

  initialize = function() {
    var fetcher, map;
    loadWeather();
    map = loadMap();
    fetcher = new MapData();
    return fetcher.fetch(function() {
      var nav, ui;
      fetcher.show(map);
      nav = new Navigator(map, fetcher.stations, fetcher.destinations);
      return ui = new Interface(map, fetcher, nav);
    });
  };

  $(document).ready(function() {
    return initialize();
  });

}).call(this);
