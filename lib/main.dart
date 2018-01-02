import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_view/map_options.dart';
import 'package:nomnom/composite_subscription.dart';
import 'package:nomnom/favorite.dart';
import 'package:nomnom/favorite_list_widget.dart';
import 'package:nomnom/favorites_manager.dart';
import 'package:map_view/map_view.dart';
import 'package:google_maps_webservice/places.dart' as places;

var apiKey = "<your_api_key>";

void main() {
  var manager = new FavoritesManager();
  MapView.setApiKey(apiKey);
  runApp(new MyApp(manager));
}

class MyApp extends StatelessWidget {
  final FavoritesManager manager;

  MyApp(this.manager); // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'NomNom',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(
        manager: manager,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.manager})
      : assert(manager != null),
        super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  final FavoritesManager manager;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MapView mapView = new MapView();
  var compositeSubscription = new CompositeSubscription();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Nom Nom"),
      ),
      body: new FavoriteListWidget(
        manager: this.widget.manager,
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _addFavorite,
        tooltip: 'Add Favorite',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future _addFavorite() async {
    mapView.show(
        new MapOptions(
            showUserLocation: true,
            title: "Choose a favorite",
            initialCameraPosition:
                new CameraPosition(new Location(45.512287, -122.645913), 18.0)),
        toolbarActions: <ToolbarAction>[new ToolbarAction("Close", 1)]);
    var sub = mapView.onMapReady.listen((_) => _updateRestaurantsAroundUser());
    compositeSubscription.add(sub);

    sub =
        mapView.onCameraChanged.listen((cam) => _updateRestaurantsAroundUser());
    compositeSubscription.add(sub);

    sub = mapView.onToolbarAction.listen((id) {
      if (id == 1) {
        mapView.dismiss();
      }
    });
    compositeSubscription.add(sub);
  }

  Future _updateRestaurantsAroundUser() async {
    var mapCenter = await mapView.centerLocation;

    var placeApi = new places.GoogleMapsPlaces(apiKey);
    var placeResponse = await placeApi.searchNearbyWithRadius(
        new places.Location(mapCenter.latitude, mapCenter.longitude), 200,
        type: "restaurant");

    if (placeResponse.hasNoResults) {
      print("No results");
      return;
    }
    var results = placeResponse.results;
    _updateMarkersFromResults(results);
    var sub = mapView.onInfoWindowTapped.listen((m) {
      var selectedResult = results.firstWhere((r) => r.id == m.id);
      if (selectedResult != null) {
        _addPlaceToFavorites(selectedResult);
      }
    });
    compositeSubscription.add(sub);
  }

  _updateMarkersFromResults(List<places.PlacesSearchResult> results) {
    var markers = results
        .map((r) => new Marker(
            r.id, r.name, r.geometry.location.lat, r.geometry.location.lng))
        .toList();
    var currentMarkers = mapView.markers;

    var markersToRemove = currentMarkers.where((m) => !markers.contains(m));
    var markersToAdd = markers.where((m) => !currentMarkers.contains(m));
    markersToRemove.forEach((m) => mapView.removeMarker(m));
    markersToAdd.forEach((m) => mapView.addMarker(m));
  }

  _addPlaceToFavorites(places.PlacesSearchResult result) {
    var staticMapProvider = new StaticMapProvider(apiKey);
    var marker = new Marker(result.id, result.name,
        result.geometry.location.lat, result.geometry.location.lng);
    var url = staticMapProvider
        .getStaticUriWithMarkers([marker], width: 340, height: 120);
    var favorite = new Favorite(result.name, result.geometry.location.lat,
        result.geometry.location.lat, result.vicinity, url.toString());
    widget.manager.addFavorite(favorite);
    mapView.dismiss();
    compositeSubscription.cancel();
  }
}
