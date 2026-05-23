import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fulusku/features/dashboard/widgets/stats_carousel.dart';

Widget _harness(List<Widget> pages) => MaterialApp(
      home: Scaffold(
        body: StatsCarousel(pages: pages),
      ),
    );

void main() {
  group('StatsCarousel', () {
    testWidgets('renders all pages and one dot per page', (tester) async {
      final pages = [
        const Text('PAGE_A'),
        const Text('PAGE_B'),
        const Text('PAGE_C'),
      ];
      await tester.pumpWidget(_harness(pages));

      // First page is on-screen.
      expect(find.text('PAGE_A'), findsOneWidget);

      // Dot indicator semantics announces the active page.
      expect(find.bySemanticsLabel('Halaman 1 dari 3'), findsOneWidget);
    });

    testWidgets('advances active dot when page changes', (tester) async {
      final pages = [
        const Text('PAGE_A'),
        const Text('PAGE_B'),
      ];
      await tester.pumpWidget(_harness(pages));

      // Drag to next page (fling left).
      await tester.fling(
        find.byType(PageView),
        const Offset(-400, 0),
        2000,
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Halaman 2 dari 2'), findsOneWidget);
    });

    testWidgets('respects custom height', (tester) async {
      await tester.pumpWidget(_harness(const [Text('X'), Text('Y')]));
      final sized = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(StatsCarousel),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sized.height, 180);
    });
  });
}
