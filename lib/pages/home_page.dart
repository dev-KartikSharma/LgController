import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/ssh_service.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onThemeChanged; // Add this

  const HomePage({super.key, required this.onThemeChanged}); // Require it

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SSHService _sshService = SSHService();
  bool _isConnected = false;
  int _selectedIndex = 0;

  // MAP STATE
  final Completer<GoogleMapController> _mapController = Completer();
  CameraPosition? _currentCameraPosition;

  // Default: Lleida, Spain (Liquid Galaxy HQ)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 12, // Remember: Your SSH Service handles the "Zoom vs Altitude" math now
  );

  @override
  void initState() {
    super.initState();
    _connectToLG();
  }

  void _connectToLG() async {
    bool result = await _sshService.connect();
    setState(() => _isConnected = result);
    if (result) _showSnackbar("Connected to Liquid Galaxy 🚀");
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // sync to lg_rig
  void _onCameraMove(CameraPosition position) {
    _currentCameraPosition = position;
  }

  void _onCameraIdle() async {
    if (_currentCameraPosition == null || !_isConnected) return;
    await _sshService.flyTo(
      _currentCameraPosition!.target.latitude,
      _currentCameraPosition!.target.longitude,
      _currentCameraPosition!.zoom,
      _currentCameraPosition!.tilt,
      _currentCameraPosition!.bearing,
    );
  }

  // navigation bar
  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      ).then((_) => _connectToLG());
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appbaar
      appBar: AppBar(
        elevation: 0,
        // NEW: Theme Toggle Button on the Left
        leading: IconButton(
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          color: Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.grey[800],
          onPressed: widget.onThemeChanged, // Calls the function in main.dart
        ),

        title: Row(
          children: [
            Icon(Icons.public, color: Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.blue, size: 28),
            const SizedBox(width: 10),
            Text(
              "LG Controller",
              style: TextStyle(
                // Auto switch between Black and White text
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.circle,
              color: _isConnected ? Colors.green : Colors.red,
              size: 14,
            ),
          )
        ],
      ),

      // Drawer
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text('LG Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
              },
            ),
          ],
        ),
      ),

      // --- BODY ---
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _initialPosition,
              zoomControlsEnabled: true,
              minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
              onMapCreated: (controller) => _mapController.complete(controller),
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDarkButton(
                      label: "Show Logo Overlay",
                      onTap: () async {
                        await _sshService.showLogo();
                        _showSnackbar("Logo Displayed");
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDarkButton(
                      label: "Fly to India Gate",
                      onTap: () async {
                        await _sshService.sendKML("india_gate.kml");
                        final c = await _mapController.future;
                        c.animateCamera(CameraUpdate.newCameraPosition(
                            const CameraPosition(
                                target: LatLng(28.6129, 77.2295),
                                zoom: 18, tilt: 45)
                        ));
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDarkButton(
                      label: "Fly to Eiffel Tower",
                      onTap: () async {
                        await _sshService.sendKML("EiffelTower.kml");
                        final c = await _mapController.future;
                        c.animateCamera(CameraUpdate.newCameraPosition(
                            const CameraPosition(target: LatLng(48.8584, 2.2945), zoom: 18, tilt: 45)
                        ));
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDarkButton(
                            label: "Clean Logo",
                            onTap: () => _sshService.cleanLogo(),
                            isSmall: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDarkButton(
                            label: "Clean Map",
                            onTap: () => _sshService.cleanKML(),
                            isSmall: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // --- BOTTOM NAV BAR ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDarkButton({
    required String label,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    // Check if the app is currently in Dark Mode
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: isSmall ? 50 : 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          // DYNAMIC BACKGROUND: Dark Grey (0xFF333333) vs Light Grey (Shade 200)
          backgroundColor: isDarkMode ? const Color(0xFF333333) : Colors.grey.shade200,

          // DYNAMIC TEXT: White vs Black
          foregroundColor: isDarkMode ? Colors.white : Colors.black,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}