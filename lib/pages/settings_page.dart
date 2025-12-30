import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _rigsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved settings from disk
  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('ip') ?? '192.168.0.0';
      _usernameController.text = prefs.getString('username') ?? 'lg';
      _passwordController.text = prefs.getString('password') ?? 'lggalaxy';
      _portController.text = prefs.getInt('port')?.toString() ?? '22';
      _rigsController.text = prefs.getInt('rigs')?.toString() ?? '3';
    });
  }

  // Save settings to disk
  Future<void> _saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', _ipController.text);
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('password', _passwordController.text);
    await prefs.setInt('port', int.tryParse(_portController.text) ?? 22);
    await prefs.setInt('rigs', int.tryParse(_rigsController.text) ?? 3);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings Saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connection Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(labelText: 'IP Address', hintText: '192.168.x.x'),
              ),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', hintText: 'lg'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: _portController,
                decoration: const InputDecoration(labelText: 'SSH Port', hintText: '22'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _rigsController,
                decoration: const InputDecoration(labelText: 'Number of Rigs', hintText: '3'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}