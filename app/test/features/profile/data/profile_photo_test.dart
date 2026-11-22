import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/fake_profile_photo_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_photo_repository.dart';
import 'package:mitlio/features/profile/data/services/profile_photo_services.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// A [width] x [height] PNG of random pixels (does not compress well).
Future<Uint8List> noisePng(int width, int height) async {
  final random = Random(7);
  final pixels = Uint8List(width * height * 4);
  for (var i = 0; i < pixels.length; i++) {
    pixels[i] = i % 4 == 3 ? 255 : random.nextInt(256);
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final image =
      (await (await descriptor.instantiateCodec()).getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<ui.Image> decode(Uint8List png) async =>
    (await (await ui.instantiateImageCodec(png)).getNextFrame()).image;

void main() {
  group('SquareCropPhotoProcessor', () {
    const processor = SquareCropPhotoProcessor();

    testWidgets('crops a landscape picture to a square within 100 kB', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final raw = await noisePng(600, 400);
        expect(raw.length, greaterThan(profilePhotoMaxBytes));
        final out = await processor.process(raw);
        expect(out, isNotNull);
        expect(out!.length, lessThanOrEqualTo(profilePhotoMaxBytes));
        final image = await decode(out);
        expect(image.width, image.height);
        expect(image.width, lessThanOrEqualTo(400));
      });
    });

    testWidgets('crops a portrait picture to a square too', (tester) async {
      await tester.runAsync(() async {
        final out = await processor.process(await noisePng(200, 500));
        final image = await decode(out!);
        expect(image.width, image.height);
        expect(image.width, lessThanOrEqualTo(200));
      });
    });

    testWidgets('never enlarges a small picture', (tester) async {
      await tester.runAsync(() async {
        final out = await processor.process(await noisePng(40, 40));
        final image = await decode(out!);
        expect((image.width, image.height), (40, 40));
      });
    });

    testWidgets('is null for bytes that are no picture', (tester) async {
      await tester.runAsync(() async {
        expect(await processor.process(Uint8List.fromList([1, 2, 3])), isNull);
        expect(await processor.process(Uint8List(0)), isNull);
      });
    });

    testWidgets('is null when it cannot get under the cap', (tester) async {
      await tester.runAsync(() async {
        const tiny = SquareCropPhotoProcessor(maxBytes: 10);
        expect(await tiny.process(await noisePng(300, 300)), isNull);
      });
    });
  });

  group('ProfilePhotoRepository', () {
    final png = Uint8List.fromList(List.filled(1000, 7));

    void contract(
      String name,
      ProfilePhotoRepository Function() make,
    ) {
      group(name, () {
        test('is empty first, then keeps, replaces and removes', () async {
          final repo = make();
          expect(((await repo.get()) as Ok).value, isNull);
          expect(await repo.save(png), isA<Ok<void, RepositoryError>>());
          expect(((await repo.get()) as Ok).value, png);
          final other = Uint8List.fromList([9, 9]);
          await repo.save(other);
          expect(((await repo.get()) as Ok).value, other);
          expect(await repo.remove(), isA<Ok<void, RepositoryError>>());
          expect(((await repo.get()) as Ok).value, isNull);
          expect(await repo.remove(), isA<Ok<void, RepositoryError>>());
        });

        test('rejects an empty or too big picture', () async {
          final repo = make();
          final tooBig = Uint8List(profilePhotoMaxBytes + 1);
          for (final bad in [Uint8List(0), tooBig]) {
            expect(
              await repo.save(bad),
              const Err<void, RepositoryError>(InvalidData('invalid: photo')),
            );
          }
          expect(((await repo.get()) as Ok).value, isNull);
        });
      });
    }

    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('photo_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    contract('in memory', FakeProfilePhotoRepository.new);
    // The file repository needs a directory per test.
    group('file', () {
      test('is empty first, then keeps, replaces and removes', () async {
        final repo = FileProfilePhotoRepository(File('${dir.path}/p.png'));
        expect(((await repo.get()) as Ok).value, isNull);
        await repo.save(png);
        expect(((await repo.get()) as Ok).value, png);
        await repo.save(Uint8List.fromList([9, 9]));
        expect(((await repo.get()) as Ok).value, [9, 9]);
        expect(dir.listSync(), hasLength(1), reason: 'no temp file is left');
        await repo.remove();
        expect(((await repo.get()) as Ok).value, isNull);
        expect(await repo.remove(), isA<Ok<void, RepositoryError>>());
      });

      test('rejects an empty or too big picture', () async {
        final repo = FileProfilePhotoRepository(File('${dir.path}/p.png'));
        final tooBig = Uint8List(profilePhotoMaxBytes + 1);
        expect(
          await repo.save(tooBig),
          const Err<void, RepositoryError>(InvalidData('invalid: photo')),
        );
        expect(dir.listSync(), isEmpty);
      });

      test('a folder that does not exist is a Storage error', () async {
        final repo = FileProfilePhotoRepository(
          File('${dir.path}/missing/p.png'),
        );
        final saved = await repo.save(png);
        expect(saved, isA<Err<void, RepositoryError>>());
        expect((saved as Err).error, isA<Storage>());
      });
    });
  });
}
