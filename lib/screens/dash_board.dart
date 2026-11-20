import 'package:material_ui/material_ui.dart';
import 'adventure_map.dart';
import 'settings/setting.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdventureMapScreen(
      onSettingsPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingScreen(),
          ),
        );
      },
    );
  }
}
