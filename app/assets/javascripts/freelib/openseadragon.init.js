function init_seadragon(_rft, _showNav) {
  var ts = new OpenSeadragon.DjTileSource("http://iris.cul.columbia.edu:8888/view/", _rft);
  var viewer = new OpenSeadragon.Viewer("map", undefined, '/assets/seadragon/');
  viewer.showNavigator = _showNav;
  viewer.openTileSource(ts);
}