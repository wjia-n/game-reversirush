import 'package:flutter/material.dart';

import '../state/club_state.dart';
import '../theme/club_theme.dart';
import 'widgets/brass_widgets.dart';

/// Club records: persisted match history and bests.
class RecordsScreen extends StatelessWidget {
  final ClubRecords records;
  final VoidCallback onBack;

  const RecordsScreen(
      {super.key, required this.records, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: records,
      builder: (_, _) => Scaffold(
        backgroundColor: Club.cream,
        body: Column(
          children: [
            ClubHeader(
              title: 'CLUB RECORDS',
              sub: 'THE LEDGER NEVER LIES',
              trailing:
                  BrassIconButton(icon: Icons.arrow_back, onTap: onBack),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  children: [
                    RallyCard(
                      child: Column(
                        children: [
                          _RecordRow(
                              label: 'DUELS CONTESTED',
                              value: '${records.gamesPlayed}'),
                          const _Divider(),
                          _RecordRow(
                              label: 'VICTORIES', value: '${records.wins}'),
                          const _Divider(),
                          _RecordRow(
                              label: 'DEFEATS', value: '${records.losses}'),
                          const _Divider(),
                          _RecordRow(
                              label: 'DEAD HEATS', value: '${records.draws}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    RallyCard(
                      child: Column(
                        children: [
                          _RecordRow(
                              label: 'WIDEST WINNING MARGIN',
                              value: '${records.bestMargin} discs'),
                          const _Divider(),
                          _RecordRow(
                              label: 'BIGGEST SINGLE FLANK',
                              value: '${records.mostFlipped} discs'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    BrassButton(
                      label: 'BACK TO LOBBY',
                      primary: true,
                      onTap: onBack,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final String label;
  final String value;
  const _RecordRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: Club.label(13,
                      color: Club.darkTeak.withValues(alpha: 0.75),
                      spacing: 1.8))),
          Text(value, style: Club.numeral(22)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Club.hairline);
  }
}
