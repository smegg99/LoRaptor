import 'package:flutter/material.dart';
import 'package:raptchat/localization/localization.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      animationDuration: const Duration(milliseconds: 250),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home),
          label: localizations.translate('screens.home.title'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.devices),
          label: localizations.translate('screens.devices.title'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.device_hub),
          label: localizations.translate('screens.mesh.title'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings),
          label: localizations.translate('screens.settings.title'),
        ),
      ],
    );
  }
}
