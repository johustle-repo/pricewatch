import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pricewatch_apk/features/admin/presentation/widgets/admin_workspace_widgets.dart';

void main() {
  Future<void> pumpHeader(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdminPageHeader(
                  eyebrow: 'Today\'s store status',
                  title: 'Sample Stall 01',
                  subtitle: 'Lingayen Public Market, Poblacion, Lingayen',
                  icon: Icons.storefront_rounded,
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.outlined(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add product'),
                      ),
                    ],
                  ),
                  metrics: const [
                    AdminHeaderMetric(
                      label: 'Need price update',
                      value: '3',
                      icon: Icons.update_rounded,
                    ),
                    AdminHeaderMetric(
                      label: 'Pending reports',
                      value: '2',
                      icon: Icons.pending_actions_outlined,
                    ),
                    AdminHeaderMetric(
                      label: 'Above SRP',
                      value: '4',
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('vendor header lays out at wide desktop width', (tester) async {
    await pumpHeader(tester, const Size(1600, 900));
  });

  testWidgets('vendor header lays out at compact desktop width', (
    tester,
  ) async {
    await pumpHeader(tester, const Size(900, 900));
  });
}
