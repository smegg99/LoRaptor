// lib/pages/mesh_page.dart
import 'package:flutter/material.dart';
import 'package:raptchat/localization/localization.dart';

class MeshScreen extends StatelessWidget {
  const MeshScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Text(localizations.translate('screens.mesh.title')),
    );
  }
}
