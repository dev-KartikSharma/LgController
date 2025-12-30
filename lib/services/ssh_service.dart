import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';


import '/commands/kml_commands.dart';

class SSHService {
  late SSHClient _client;

  // connection logic
  Future<bool> connect() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String host = prefs.getString('ip') ?? '192.168.0.10';
      final int port = prefs.getInt('port') ?? 22;
      final String username = prefs.getString('username') ?? 'lg';
      final String password = prefs.getString('password') ?? 'lg';

      final socket = await SSHSocket.connect(host, port);
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      return true;
    } catch (e) {
      return Future.error(e);
    }
  }

  // Execute Command
  Future<void> _execute(String command) async {
    try {
      if (_client.isClosed) return;
      await _client.run(command);
    } catch (e) {
      return Future.error(e);
    }
  }

  // upload files to master
  Future<void> _uploadAsset(String assetPath, String remotePath) async {
    try {
      if (_client.isClosed) return;
      final sftp = await _client.sftp();
      final file = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List();
      await file.write(Stream.value(bytes).cast());
      await file.close();
    } catch (e) {
      return Future.error(e);
    }
  }

  int getLeftScreen() {
    int totalScreens = 3;
    return (totalScreens / 2).floor() + 2;
  }

  Future<void> showLogo() async {
    int leftRig = getLeftScreen();
    String openLogoKML = KMLCommands.screenOverlayImage(
      "http://lg1:81/lg_logo.png",
      x: 0.38,
      y: 1,
    );

    try {
      await _uploadAsset('assets/images/lg_logo.png', '/var/www/html/lg_logo.png');
      await _execute("echo '$openLogoKML' > /var/www/html/kml/slave_$leftRig.kml");
    } catch (e) {
      return Future.error(e);
    }
  }

  // clean logo overlay
  Future<void> cleanLogo() async {
    int leftRig = getLeftScreen();
    String blankKml = KMLCommands.blankKml();
    await _execute("echo '$blankKml' > /var/www/html/kml/slave_$leftRig.kml");
  }

  // Sync Maps
  Future<void> flyTo(double lat, double lng, double zoom, double tilt, double bearing) async {
    try {
      String lookAt = KMLCommands.lookAtLinear(lat, lng, zoom, tilt, bearing);
      await _execute('echo "flytoview=$lookAt" > /tmp/query.txt');
    } catch (e) {
      return Future.error(e);
    }
  }

  //Fly To Cities
  // Sends a full KML file to the Master
  Future<void> sendKML(String kmlFileName) async {
    try {
      String kmlContent = await rootBundle.loadString('assets/kmls/$kmlFileName');
      await _execute("echo '$kmlContent' > /var/www/html/kmls.txt");
    } catch (e) {
      return Future.error(e);
    }
  }

  // Clean Map
  Future<void> cleanKML() async {
    // Empty the master KML file to stop any tour
    await _execute("echo '' > /var/www/html/kmls.txt");
  }
}