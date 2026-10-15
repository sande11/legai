import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/legai_colors.dart';
import '../../../../core/theme/legai_theme.dart';
import '../../domain/entities/jurisdiction.dart';
import '../cubit/settings_cubit.dart';

/// Bottom sheet listing supported countries.
Future<void> showJurisdictionPicker(BuildContext context) {
  final cubit = context.read<SettingsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final c = context.colors;
      final current = cubit.state.jurisdictionCode;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scroll) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text('Whose law?', style: context.text.headlineMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'LegAI answers for the country you choose.',
                style: context.text.bodySmall?.copyWith(fontSize: 14),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                children: [
                  for (final j in Jurisdictions.supported)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      title: Text(j.name, style: context.text.titleSmall),
                      trailing: j.code == current
                          ? Icon(LucideIcons.check, color: c.goldIcon)
                          : null,
                      selected: j.code == current,
                      onTap: () {
                        cubit.setJurisdiction(j.code);
                        Navigator.of(context).pop();
                      },
                    ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 12),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
