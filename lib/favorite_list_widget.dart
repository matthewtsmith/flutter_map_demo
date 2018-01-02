import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nomnom/favorite.dart';
import 'package:nomnom/favorites_manager.dart';

class FavoriteListWidget extends StatefulWidget {
  final FavoritesManager manager;

  FavoriteListWidget({@required this.manager}) : assert(manager != null);

  @override
  State<StatefulWidget> createState() => new _FavoriteListState();
}

class _FavoriteListState extends State<FavoriteListWidget> {
  List<Favorite> _favorites;

  @override
  void initState() {
    super.initState();
    _favorites = widget.manager.favorites;
    widget.manager.onFavoritesChanged.listen((_) {
      setState(() => _favorites = widget.manager.favorites);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_favorites == null || _favorites.length == 0) {
      return new Center(
        child: new Text("You have no favorites."),
      );
    }
    return new ListView.builder(
        itemCount: _favorites.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (BuildContext ctx, int index) {
          return new FavoriteCard(_favorites[index]);
        });
  }
}

class FavoriteCard extends StatelessWidget {
  final Favorite favorite;

  FavoriteCard(this.favorite);

  @override
  Widget build(BuildContext context) {
    return new Container(
      padding: const EdgeInsets.only(top: 12.0),
      child: new Card(
        elevation: 3.0,
        child: new Container(
          padding: const EdgeInsets.all(8.0),
          child: new Column(
            children: <Widget>[
              new Container(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: new Text(
                  favorite.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: new TextStyle(
                      fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
              ),
              new Text(favorite.address),
              new Container(
                padding: const EdgeInsets.only(top: 12.0),
                child: new Image.network(favorite.staticMapUrl),
              )
            ],
          ),
        ),
      ),
    );
  }
}
