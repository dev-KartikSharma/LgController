import 'dart:math';
class KMLCommands {
  // The "Sticker" Logo Overlay
  static String screenOverlayImage(String imageUrl, {double x = 0.95, double y = 0.95}) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>LG Logo Overlay</name>
    <Folder>
      <name>Logo</name>
      <ScreenOverlay>
        <name>LogoOverlay</name>
        <Icon>
          <href>$imageUrl</href>
        </Icon>
        <overlayXY x="1" y="1" xunits="fraction" yunits="fraction"/>
        <screenXY x="$x" y="$y" xunits="fraction" yunits="fraction"/>
        <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
        <size x="300" y="0" xunits="pixels" yunits="pixels"/>
      </ScreenOverlay>
    </Folder>
  </Document>
</kml>
    ''';
  }
  static String lookAtLinear(double latitude, double longitude, double zoom, double tilt, double bearing) {
    double range = 59165755.0 / pow(2, zoom);
    if (range < 1500) {
      range = 1500;
    }
    return '<LookAt>'
        '<longitude>$longitude</longitude>'
        '<latitude>$latitude</latitude>'
        '<range>$range</range>'
        '<tilt>$tilt</tilt>'
        '<heading>$bearing</heading>'
        '<gx:altitudeMode>relativeToGround</gx:altitudeMode>'
        '</LookAt>';
  }

  static String blankKml() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"><Document></Document></kml>''';
  }
}