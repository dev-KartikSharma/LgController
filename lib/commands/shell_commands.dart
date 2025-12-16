class ShellCommands {
  // Logic to find the left screen (LG3)
  static int getLeftScreen() {
    return 2; // Or use the dynamic math: (screens / 2) + 2
  }

  // The command to Auto-Install the Network Link on the Left Screen
  static String installRigWrapper() {
    int slaveNum = getLeftScreen();
    // We target the corresponding slave file (slave_2.kml)
    String targetFile = "slave_$slaveNum.kml";

    return '''
sshpass -p lggalaxy ssh -t lg3 'echo "<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?>
<kml xmlns=\\"http://www.opengis.net/kml/2.2\\">
  <NetworkLink>
    <Link>
      <href>http://lg1/kml/$targetFile</href>
      <refreshMode>onInterval</refreshMode>
      <refreshInterval>1</refreshInterval>
    </Link>
  </NetworkLink>
</kml>" > /var/www/html/slave_${slaveNum}_link.kml'
''';
  }

  // Command to create the KML folder if missing
  static String makeKmlFolder() {
    return 'mkdir -p /var/www/html/kml && chmod -R 777 /var/www/html/kml';
  }
}