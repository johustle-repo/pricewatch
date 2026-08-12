import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pricewatch_apk/features/vendor/presentation/screens/vendor_dashboard_screen.dart';

void main() {
  testWidgets('fresh vendor dashboard renders in the web shell body', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: VendorDashboardScreen(
              data: const VendorDashboardData(
                storeName: 'Sample Stall 01',
                location: 'Lingayen Public Market',
                products: [],
                staleCount: 0,
                aboveSrpCount: 0,
                pendingReportCount: 0,
              ),
              onAddProduct: () {},
              onRefresh: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sample Stall 01'), findsOneWidget);
    expect(find.text('Current price register'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fresh vendor dashboard renders at compact web width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VendorDashboardScreen(
            data: const VendorDashboardData(
              storeName: 'Sample Stall 01',
              location: 'Lingayen Public Market',
              products: [],
              staleCount: 1,
              aboveSrpCount: 2,
              pendingReportCount: 3,
            ),
            onAddProduct: () {},
            onRefresh: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Needs attention'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vendor mobile dashboard is a stable single-page layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VendorDashboardScreen(
            data: const VendorDashboardData(
              storeName: 'Sample Stall 01',
              location: 'Lingayen Public Market, Poblacion, Lingayen',
              products: [],
              staleCount: 1,
              aboveSrpCount: 2,
              pendingReportCount: 3,
            ),
            onAddProduct: () {},
            onRefresh: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('vendor-mobile-dashboard')), findsOneWidget);
    expect(find.text('Store snapshot'), findsOneWidget);
    expect(find.text('Add price'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
