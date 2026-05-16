import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
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
  });

  group('CameraScreen', () {
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
      when(() => cubit.state).thenReturn(const ScannerUploading());
      when(() => cubit.stream)
          .thenAnswer((_) => Stream.value(const ScannerUploading()));
      await tester.pumpWidget(_buildSubject(cubit));
      expect(find.text('Upload PDF'), findsNothing);
      expect(find.text('Buka Kamera'), findsNothing);
    });

    testWidgets('hides action buttons while processing', (tester) async {
      when(() => cubit.state).thenReturn(const ScannerProcessing());
      when(() => cubit.stream)
          .thenAnswer((_) => Stream.value(const ScannerProcessing()));
      await tester.pumpWidget(_buildSubject(cubit));
      expect(find.text('Upload PDF'), findsNothing);
    });
  });
}
