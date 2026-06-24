import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_radio/core/responsive/responsive_layout.dart';

void main() {
  group('Breakpoints', () {
    test('has correct values', () {
      expect(Breakpoints.phone, equals(600));
      expect(Breakpoints.tablet, equals(900));
      expect(Breakpoints.desktop, equals(1200));
    });
  });

  group('ResponsiveLayout widget', () {
    testWidgets('shows phone widget on small screens', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            phone: Text('Phone'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows tablet widget on medium screens', (tester) async {
      tester.view.physicalSize = const Size(700, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            phone: Text('Phone'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Phone'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('shows desktop widget on large screens', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            phone: Text('Phone'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Phone'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('falls back to phone when tablet not provided', (tester) async {
      tester.view.physicalSize = const Size(700, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            phone: Text('Phone'),
          ),
        ),
      );

      expect(find.text('Phone'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('CenteredContent widget', () {
    testWidgets('constrains width', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CenteredContent(
              maxWidth: 500,
              child: Text('Centered'),
            ),
          ),
        ),
      );

      expect(find.text('Centered'), findsOneWidget);
    });
  });

  group('getAdaptiveColumnCount', () {
    testWidgets('returns correct count for phone', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      late int columns;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              columns = getAdaptiveColumnCount(context);
              return Container();
            },
          ),
        ),
      );

      expect(columns, equals(2));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
