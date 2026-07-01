import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapmemo/core/connectivity/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> controller;

  setUp(() {
    connectivity = MockConnectivity();
    controller = StreamController<List<ConnectivityResult>>.broadcast();
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => controller.stream);
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
  });

  tearDown(() => controller.close());

  test('starts online once the initial check resolves', () async {
    final provider = ConnectivityProvider(connectivity: connectivity);
    expect(provider.isOnline, isTrue);

    await Future<void>.delayed(Duration.zero);
    expect(provider.isOnline, isTrue);
  });

  test('flips to offline when connectivity is lost', () async {
    final provider = ConnectivityProvider(connectivity: connectivity);
    await Future<void>.delayed(Duration.zero);

    var notified = false;
    provider.addListener(() => notified = true);

    controller.add([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.isOnline, isFalse);
    expect(notified, isTrue);
  });

  test('flips back online when connectivity returns', () async {
    final provider = ConnectivityProvider(connectivity: connectivity);
    controller.add([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.isOnline, isFalse);

    controller.add([ConnectivityResult.mobile]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.isOnline, isTrue);
  });
}
