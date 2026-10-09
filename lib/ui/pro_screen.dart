import 'package:flutter/material.dart';

import '../audio/club_audio.dart';
import '../services/iap_service.dart';
import '../theme/club_theme.dart';
import 'widgets/brass_widgets.dart';

/// Reversi Rush Pro: Free-vs-Pro comparison + tip jar.
/// Store products are created by Wajiha in Play Console; until they exist
/// the screen shows an honest "available after store setup" state.
class ProScreen extends StatelessWidget {
  final StoreService store;
  final ClubAudio audio;
  final VoidCallback onBack;

  const ProScreen({
    super.key,
    required this.store,
    required this.audio,
    required this.onBack,
  });

  static const _rows = [
    ('Full game — all modes', true, true),
    ('3 automaton calibres', true, true),
    ('Blitz chrono duels', true, true),
    ('12 table themes', true, true),
    ('9 disc pours', true, true),
    ('Custom table creator', false, true),
    ('Custom disc creator', false, true),
    ('No ads, ever', false, true),
    ('Founder\'s laurel badge', false, true),
    ('Priority table requests', false, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Club.cream,
      body: Column(
        children: [
          ClubHeader(
            title: 'REVERSI RUSH PRO',
            sub: 'THE MEMBERS\' TABLE',
            trailing: BrassIconButton(
              icon: Icons.check,
              onTap: () {
                audio.play(ClubSound.click);
                onBack();
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  RallyCard(
                    child: Column(
                      children: [
                        Text('FREE  vs  PRO',
                            style: Club.label(15,
                                color: Club.darkTeak, spacing: 3.0)),
                        const SizedBox(height: 4),
                        Text(
                          'One purchase. Yours forever. No subscriptions, no tricks.',
                          textAlign: TextAlign.center,
                          style: Club.bodyText(12,
                              color:
                                  Club.darkTeak.withValues(alpha: 0.65)),
                        ),
                        const SizedBox(height: 12),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1),
                          },
                          children: [
                            TableRow(
                              children: [
                                const SizedBox.shrink(),
                                Center(
                                    child: Text('FREE',
                                        style: Club.label(11,
                                            color: Club.darkTeak
                                                .withValues(alpha: 0.6)))),
                                Center(
                                    child: Text('PRO',
                                        style: Club.label(11,
                                            color: Club.brassDeep))),
                              ],
                            ),
                            for (final (label, free, pro) in _rows)
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    child: Text(label,
                                        style: Club.bodyText(12)),
                                  ),
                                  Center(
                                      child: _mark(free, Club.darkTeak
                                          .withValues(alpha: 0.55))),
                                  Center(child: _mark(pro, Club.brassDeep)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ValueListenableBuilder<bool>(
                    valueListenable: store.proPurchased,
                    builder: (_, owned, _) {
                      if (owned) {
                        return RallyCard(
                          child: Column(
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: Club.brassDeep, size: 40),
                              const SizedBox(height: 8),
                              Text('PRO MEMBER',
                                  style: Club.label(16,
                                      color: Club.brassDeep, spacing: 3.0)),
                              const SizedBox(height: 4),
                              Text(
                                'Your laurel is stamped. Every table, every pour — unlocked.',
                                textAlign: TextAlign.center,
                                style: Club.bodyText(12,
                                    color: Club.darkTeak
                                        .withValues(alpha: 0.65)),
                              ),
                            ],
                          ),
                        );
                      }
                      final product = store.proProduct;
                      return RallyCard(
                        child: Column(
                          children: [
                            Text('UNLOCK PRO',
                                style: Club.label(15,
                                    color: Club.darkTeak, spacing: 2.6)),
                            const SizedBox(height: 4),
                            Text(
                              store.storeReady && product != null
                                  ? 'One-time purchase · ${product.price}'
                                  : 'The Pro table opens once the store listing is live.',
                              textAlign: TextAlign.center,
                              style: Club.bodyText(12,
                                  color: Club.darkTeak
                                      .withValues(alpha: 0.65)),
                            ),
                            const SizedBox(height: 12),
                            if (store.storeReady && product != null)
                              ValueListenableBuilder<bool>(
                                valueListenable: store.purchaseInProgress,
                                builder: (_, busy, _) => BrassButton(
                                  label: busy
                                      ? 'CONTACTING STORE…'
                                      : 'BECOME PRO · ${product.price}',
                                  primary: true,
                                  onTap: busy ? null : store.buyPro,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Club.hairline,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Club.brass),
                                ),
                                child: Text(
                                  'AVAILABLE AFTER STORE SETUP',
                                  textAlign: TextAlign.center,
                                  style: Club.label(12,
                                      color: Club.darkTeak
                                          .withValues(alpha: 0.6)),
                                ),
                              ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: store.restore,
                              child: Text('RESTORE PURCHASE',
                                  style: Club.label(11,
                                      color: Club.brassDeep)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  RallyCard(
                    child: Column(
                      children: [
                        Text('TIP JAR',
                            style: Club.label(15,
                                color: Club.darkTeak, spacing: 2.6)),
                        const SizedBox(height: 4),
                        Text(
                          'Reversi Rush is free forever. If the club made you smile, buy the house a coffee.',
                          textAlign: TextAlign.center,
                          style: Club.bodyText(12,
                              color:
                                  Club.darkTeak.withValues(alpha: 0.65)),
                        ),
                        const SizedBox(height: 12),
                        if (store.storeReady)
                          Row(
                            children: [
                              Expanded(
                                  child: _tipButton(
                                      '☕', 'COFFEE', store.coffeeProduct)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _tipButton('🍫', 'CHOCOLATE',
                                      store.chocolateProduct)),
                            ],
                          )
                        else
                          Text(
                            'Tips open once the store listing is live.',
                            style: Club.bodyText(12,
                                color: Club.darkTeak
                                    .withValues(alpha: 0.55)),
                          ),
                        ValueListenableBuilder<String?>(
                          valueListenable: store.lastThanks,
                          builder: (_, thanks, _) => thanks == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding:
                                      const EdgeInsets.only(top: 10),
                                  child: Text(thanks,
                                      style: Club.label(12,
                                          color: Club.brassDeep)),
                                ),
                        ),
                        ValueListenableBuilder<String?>(
                          valueListenable: store.purchaseError,
                          builder: (_, err, _) => err == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding:
                                      const EdgeInsets.only(top: 6),
                                  child: Text(err,
                                      style: Club.label(11,
                                          color: Club.crimson)),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mark(bool yes, Color color) => Icon(
        yes ? Icons.check_circle : Icons.remove_circle_outline,
        color: color,
        size: 20,
      );

  Widget _tipButton(String emoji, String label, product) {
    if (product == null) {
      return Opacity(
        opacity: 0.5,
        child: BrassButton(label: label, onTap: null),
      );
    }
    return BrassButton(
      label: '$emoji $label',
      sublabel: product.price as String,
      onTap: () => store.buyTip(product),
    );
  }
}
