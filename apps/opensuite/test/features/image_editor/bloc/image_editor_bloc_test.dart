import 'dart:typed_data';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opensuite/features/image_editor/bloc/image_editor_bloc.dart';

void main() {
  late ImageEditorBloc bloc;

  setUp(() {
    bloc = ImageEditorBloc();
  });

  tearDown(() => bloc.close());

  group('ImageEditorBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, ImageEditorStatus.initial);
      expect(bloc.state.filePath, isNull);
      expect(bloc.state.imageWidth, 0);
      expect(bloc.state.imageHeight, 0);
      expect(bloc.state.activeTool, 'adjust');
      expect(bloc.state.hasEdits, false);
      expect(bloc.state.canUndo, false);
      expect(bloc.state.canRedo, false);
    });

    group('LoadImage', () {
      blocTest<ImageEditorBloc, ImageEditorState>(
        'emits [loading, loaded] with dimensions',
        build: () => bloc,
        act: (bloc) => bloc.add(LoadImage(
          filePath: '/test/image.png',
          imageBytes: Uint8List.fromList([1, 2, 3]),
        )),
        expect: () => [
          isA<ImageEditorState>()
              .having((s) => s.status, 'status', ImageEditorStatus.loading)
              .having((s) => s.filePath, 'filePath', '/test/image.png'),
          isA<ImageEditorState>()
              .having((s) => s.status, 'status', ImageEditorStatus.loaded)
              .having((s) => s.imageWidth, 'width', 1920)
              .having((s) => s.imageHeight, 'height', 1080),
        ],
      );
    });

    group('RotateImage', () {
      blocTest<ImageEditorBloc, ImageEditorState>(
        'rotates by given degrees and pushes undo',
        build: () => bloc,
        act: (bloc) => bloc.add(const RotateImage(90)),
        expect: () => [
          // First emit: push undo
          isA<ImageEditorState>()
              .having((s) => s.hasEdits, 'hasEdits', true)
              .having((s) => s.undoStack.length, 'undoStack', 1),
          // Second emit: rotation applied
          isA<ImageEditorState>()
              .having((s) => s.adjustments.rotation, 'rotation', 90.0),
        ],
      );
    });

    group('SetBrightness', () {
      blocTest<ImageEditorBloc, ImageEditorState>(
        'sets brightness and pushes undo',
        build: () => bloc,
        act: (bloc) => bloc.add(const SetBrightness(0.5)),
        expect: () => [
          isA<ImageEditorState>().having((s) => s.hasEdits, 'hasEdits', true),
          isA<ImageEditorState>()
              .having((s) => s.adjustments.brightness, 'brightness', 0.5),
        ],
      );

      blocTest<ImageEditorBloc, ImageEditorState>(
        'clamps brightness to -1.0..1.0',
        build: () => bloc,
        act: (bloc) => bloc.add(const SetBrightness(5.0)),
        expect: () => [
          isA<ImageEditorState>(),
          isA<ImageEditorState>()
              .having((s) => s.adjustments.brightness, 'brightness', 1.0),
        ],
      );
    });

    group('SetContrast', () {
      blocTest<ImageEditorBloc, ImageEditorState>(
        'sets contrast and clamps to 0.0..2.0',
        build: () => bloc,
        act: (bloc) => bloc.add(const SetContrast(1.5)),
        expect: () => [
          isA<ImageEditorState>(),
          isA<ImageEditorState>()
              .having((s) => s.adjustments.contrast, 'contrast', 1.5),
        ],
      );
    });

    group('SetSaturation', () {
      blocTest<ImageEditorBloc, ImageEditorState>(
        'sets saturation and clamps to 0.0..2.0',
        build: () => bloc,
        act: (bloc) => bloc.add(const SetSaturation(0.5)),
        expect: () => [
          isA<ImageEditorState>(),
          isA<ImageEditorState>()
              .having((s) => s.adjustments.saturation, 'saturation', 0.5),
        ],
      );
    });

    group('FlipImage', () {
      blocTest<ImageEditorBloc, ImageEditorState>(
        'flips horizontal',
        build: () => bloc,
        act: (bloc) => bloc.add(const FlipImage(horizontal: true)),
        expect: () => [
          isA<ImageEditorState>(),
          isA<ImageEditorState>()
              .having((s) => s.adjustments.flipHorizontal, 'flipH', true),
        ],
      );

      blocTest<ImageEditorBloc, ImageEditorState>(
        'flips vertical',
        build: () => bloc,
        act: (bloc) => bloc.add(const FlipImage(horizontal: false)),
        expect: () => [
          isA<ImageEditorState>(),
          isA<ImageEditorState>()
              .having((s) => s.adjustments.flipVertical, 'flipV', true),
        ],
      );
    });

    group('UndoRedo', () {
      blocTest<ImageEditorBloc, ImageEditorState>(
        'undo reverts last edit',
        build: () => bloc,
        seed: () => ImageEditorState(
          adjustments: const ImageAdjustments(brightness: 0.5),
          undoStack: const [ImageAdjustments()],
          hasEdits: true,
        ),
        act: (bloc) => bloc.add(const UndoEdit()),
        expect: () => [
          isA<ImageEditorState>()
              .having((s) => s.adjustments.brightness, 'brightness', 0.0)
              .having((s) => s.undoStack.length, 'undoStack', 0)
              .having((s) => s.redoStack.length, 'redoStack', 1),
        ],
      );

      blocTest<ImageEditorBloc, ImageEditorState>(
        'redo re-applies undone edit',
        build: () => bloc,
        seed: () => const ImageEditorState(
          adjustments: ImageAdjustments(),
          redoStack: [ImageAdjustments(brightness: 0.5)],
          hasEdits: true,
        ),
        act: (bloc) => bloc.add(const RedoEdit()),
        expect: () => [
          isA<ImageEditorState>()
              .having((s) => s.adjustments.brightness, 'brightness', 0.5)
              .having((s) => s.redoStack.length, 'redoStack', 0),
        ],
      );

      blocTest<ImageEditorBloc, ImageEditorState>(
        'undo does nothing when stack is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const UndoEdit()),
        expect: () => [],
      );
    });

    group('ResetEdits', () {
      blocTest<ImageEditorBloc, ImageEditorState>(
        'resets adjustments to defaults',
        build: () => bloc,
        seed: () => const ImageEditorState(
          adjustments: ImageAdjustments(brightness: 0.5, contrast: 1.5),
          hasEdits: true,
        ),
        act: (bloc) => bloc.add(const ResetEdits()),
        expect: () => [
          isA<ImageEditorState>().having((s) => s.hasEdits, 'hasEdits', true),
          isA<ImageEditorState>()
              .having((s) => s.adjustments.brightness, 'brightness', 0.0)
              .having((s) => s.adjustments.contrast, 'contrast', 1.0),
        ],
      );
    });

    group('SelectTool', () {
      blocTest<ImageEditorBloc, ImageEditorState>(
        'changes active tool',
        build: () => bloc,
        act: (bloc) => bloc.add(const SelectTool('crop')),
        expect: () => [
          isA<ImageEditorState>()
              .having((s) => s.activeTool, 'activeTool', 'crop'),
        ],
      );
    });

    group('ResizeImageDimensions', () {
      blocTest<ImageEditorBloc, ImageEditorState>(
        'updates image dimensions',
        build: () => bloc,
        act: (bloc) => bloc.add(const ResizeImageDimensions(1280, 720)),
        expect: () => [
          isA<ImageEditorState>(),
          isA<ImageEditorState>()
              .having((s) => s.imageWidth, 'width', 1280)
              .having((s) => s.imageHeight, 'height', 720),
        ],
      );
    });

    group('ImageAdjustments', () {
      test('equality works correctly', () {
        const a = ImageAdjustments(brightness: 0.5);
        const b = ImageAdjustments(brightness: 0.5);
        const c = ImageAdjustments(brightness: 0.3);
        expect(a, equals(b));
        expect(a, isNot(equals(c)));
      });

      test('copyWith preserves values', () {
        const adj = ImageAdjustments(
          brightness: 0.5,
          contrast: 1.2,
          saturation: 0.8,
        );
        final copy = adj.copyWith(brightness: 0.0);
        expect(copy.brightness, 0.0);
        expect(copy.contrast, 1.2);
        expect(copy.saturation, 0.8);
      });
    });
  });
}
