import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fulusku/features/scanner/cubit/scanner_cubit.dart';
import 'package:fulusku/features/scanner/cubit/scanner_state.dart';
import 'package:fulusku/features/scanner/view/camera_screen.dart';

class MockScannerCubit extends MockCubit<ScannerState>
    implements ScannerCubit {}

Widget _buildSubject(ScannerCubit cubit) {
  return MaterialApp(
    home: BlocProvider<ScannerCubit>.value(
      value: cubit,
      child: const CameraScreen(),
    ),
  );
}

void main() {
  late MockScannerCubit cubit;

  setUp(() {
    cubit = MockScannerCubit();
    when(() => cubit.state).thenReturn(const ScannerIdle());
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());

    // Mock image_picker platform channel so initState auto-trigger doesn't throw
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      (call) async => null, // simulate user cancellation
    );
  });

  tearDown(() {
    reset(cubit);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      null,
    );
  });

  group('CameraScreen', () {
    // TODO: add tap test in Task 3 when FilePicker is injectable
    testWidgets('shows Upload PDF button in idle state', (tester) async {
      await tester.pumpWidget(_buildSubject(cubit));
      expect(find.text('Upload PDF'), findsOneWidget);
    });

    testWidgets('shows Buka Kamera button in idle state', (tester) async {
      await tester.pumpWidget(_buildSubject(cubit));
      expect(find.text('Buka Kamera'), findsOneWidget);
    });

    testWidgets('shows Pilih dari Galeri button in idle state', (tester) async {
      await tester.pumpWidget(_buildSubject(cubit));
      expect(find.text('Pilih dari Galeri'), findsOneWidget);
    });

    testWidgets('hides action buttons while uploading', (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([const ScannerUploading()]),
        initialState: const ScannerUploading(),
      );
      await tester.pumpWidget(_buildSubject(cubit));
      expect(find.text('Upload PDF'), findsNothing);
      expect(find.text('Buka Kamera'), findsNothing);
      expect(find.text('Pilih dari Galeri'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides action buttons while processing', (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([const ScannerProcessing()]),
        initialState: const ScannerProcessing(),
      );
      await tester.pumpWidget(_buildSubject(cubit));
      expect(find.text('Upload PDF'), findsNothing);
      expect(find.text('Buka Kamera'), findsNothing);
      expect(find.text('Pilih dari Galeri'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
