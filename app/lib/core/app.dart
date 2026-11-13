import 'package:material_ui/material_ui.dart';

/// Root widget. Routing, theme and DI are added in P3-T01.
class MitlioApp extends StatelessWidget {
  const MitlioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'mitlio',
      home: Scaffold(body: Center(child: Text('mitlio'))),
    );
  }
}
