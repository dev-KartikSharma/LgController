import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';

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
      final String password = prefs.getString('password') ?? 'lggalaxy';

      final socket = await SSHSocket.connect(host, port);
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      print('Connected to $host');
      return true;
    } catch (e) {
      print('Connection failed: $e');
      return false;
    }
  }

  // --- HELPER: Execute Command ---
  Future<void> _execute(String command) async {
    try {
      if (_client.isClosed) return;
      await _client.run(command);
    } catch (e) {
      print('Command error: $e');
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
      print('Upload failed: $e');
    }
  }

  int getLeftScreen() {
    int totalScreens = 3;
    return (totalScreens / 2).floor() + 2;
  }

  Future<void> showLogo() async {
    int leftRig = getLeftScreen();
    String openLogoKML = KMLCommands.screenOverlayImage(
      "http://lg1/lg_logo.png",
      x: 0.38,
      y: 1,
    );

    try {
      print("Displaying Logo on Slave_$leftRig");
      await _uploadAsset('assets/images/lg_logo.png', '/var/www/html/lg_logo.png');
      await _execute("echo '$openLogoKML' > /var/www/html/kml/slave_$leftRig.kml");
      print('Logo sent to slave_$leftRig.kml');
    } catch (e) {
      print(' Error showing logo: $e');
    }
  }

  // clean logo overlay
  Future<void> cleanLogo() async {
    int leftRig = getLeftScreen();
    String blankKml = KMLCommands.blankKml();
    print("Cleaning logo on slave_$leftRig");
    await _execute("echo '$blankKml' > /var/www/html/kml/slave_$leftRig.kml");
  }

  // --- TOPIC 3: SYNC MAP (FlyToView) ---
  Future<void> flyTo(double lat, double lng, double zoom, double tilt, double bearing) async {
    try {
      // 1. Generate the LookAt string (converts Phone Zoom -> LG Range)
      String lookAt = KMLCommands.lookAtLinear(lat, lng, zoom, tilt, bearing);

      // 2. Write to /tmp/query.txt for instant movement
      await _execute('echo "flytoview=$lookAt" > /tmp/query.txt');
    } catch (e) {
      print('Error syncing map: $e');
    }
  }

  // --- TASK: Fly To Cities (Standard KML) ---
  // Sends a full KML file (like India Gate) to the Master
  Future<void> sendKML(String kmlFileName) async {
    try {
      String kmlContent = await rootBundle.loadString('assets/kmls/$kmlFileName');

      // Write to kmls.txt (The main input for the Master)
      await _execute("echo '$kmlContent' > /var/www/html/kmls.txt");
    } catch (e) {
      print('Error sending KML: $e');
    }
  }

  // --- TASK: Clean Map ---
  Future<void> cleanKML() async {
    // Empty the master KML file to stop any tours/orbits
    await _execute("echo '' > /var/www/html/kmls.txt");
  }
}