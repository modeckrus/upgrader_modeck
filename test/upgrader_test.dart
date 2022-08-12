/*
 * Copyright (c) 2018-2022 Larry Aasen. All rights reserved.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader_modeck/upgrader_modeck.dart';

import 'fake_appcast.dart';
import 'mock_itunes_client.dart';
import 'mock_play_store_client.dart';

// Platform.operatingSystem can be "macos" or "linux" in a unit test.
// defaultTargetPlatform is TargetPlatform.android in a unit test.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await preferences.clear();
    return true;
  });
  final androidId = 'com.larryaasen.upgrader';
  final iosId = 'com.larryaasen.upgrader';
  testWidgets('test Upgrader class', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(platform: TargetPlatform.iOS, client: client, androidId: androidId, iosId: iosId);

    expect(tester.takeException(), null);
    await tester.pumpAndSettle();
    try {
      expect(upgrader.appName(), 'Upgrader');
    } catch (e) {
      expect(e, upgrader.notInitializedExceptionMessage);
    }

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '1.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    // Calling initialize() a second time should do nothing
    await upgrader.initialize();

    expect(upgrader.appName(), 'Upgrader');
    expect(upgrader.currentAppStoreVersion(), '5.6');
    expect(upgrader.currentInstalledVersion(), '1.9.9');
    expect(upgrader.isUpdateAvailable(), true);

    upgrader.installAppStoreVersion('1.2.3');
    expect(upgrader.currentAppStoreVersion(), '1.2.3');
  }, skip: false);

  testWidgets('test installAppStoreListingURL', (WidgetTester tester) async {
    final upgrader = Upgrader(androidId: androidId, iosId: iosId);
    upgrader.installAppStoreListingURL(
        'https://itunes.apple.com/us/app/google-maps-transit-food/id585027354?mt=8&uo=4');

    expect(upgrader.currentAppStoreListingURL(),
        'https://itunes.apple.com/us/app/google-maps-transit-food/id585027354?mt=8&uo=4');
  }, skip: false);

  testWidgets('test UpgradeWidget', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true, androidId: androidId, iosId: iosId);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onUpdate = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isUpdateAvailable(), true);
    expect(upgrader.isTooSoon(), false);

    expect(upgrader.messages, isNotNull);

    expect(upgrader.messages.buttonTitleIgnore, 'IGNORE');
    expect(upgrader.messages.buttonTitleLater, 'LATER');
    expect(upgrader.messages.buttonTitleUpdate, 'UPDATE NOW');
    expect(upgrader.messages.releaseNotes, 'Release Notes');

    upgrader.messages = MyUpgraderMessages();

    expect(upgrader.messages.buttonTitleIgnore, 'aaa');
    expect(upgrader.messages.buttonTitleLater, 'bbb');
    expect(upgrader.messages.buttonTitleUpdate, 'ccc');
    expect(upgrader.messages.releaseNotes, 'ddd');

    await tester.pumpWidget(_MyWidget(upgrader_modeck: upgrader));

    expect(find.text('Upgrader test'), findsOneWidget);
    expect(find.text('Upgrading'), findsOneWidget);

    // Pump the UI so the upgrader_modeck can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), true);

    expect(find.text(upgrader.messages.title), findsOneWidget);
    expect(find.text(upgrader.message()), findsOneWidget);
    expect(find.text(upgrader.messages.releaseNotes), findsOneWidget);
    expect(find.text(upgrader.releaseNotes!), findsOneWidget);
    expect(find.text(upgrader.messages.prompt), findsOneWidget);
    expect(find.byType(TextButton), findsNWidgets(3));
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsOneWidget);
    expect(find.text(upgrader.messages.buttonTitleLater), findsOneWidget);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsOneWidget);
    expect(find.text(upgrader.messages.releaseNotes), findsOneWidget);

    await tester.tap(find.text(upgrader.messages.buttonTitleUpdate));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsNothing);
    expect(find.text(upgrader.messages.releaseNotes), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  }, skip: false);

  testWidgets('test UpgradeWidget Cupertino', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true, androidId: androidId, iosId: iosId);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onUpdate = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isUpdateAvailable(), true);
    expect(upgrader.isTooSoon(), false);

    expect(upgrader.messages, isNotNull);

    expect(upgrader.messages.buttonTitleIgnore, 'IGNORE');
    expect(upgrader.messages.buttonTitleLater, 'LATER');
    expect(upgrader.messages.buttonTitleUpdate, 'UPDATE NOW');

    upgrader.messages = MyUpgraderMessages();

    expect(upgrader.messages.buttonTitleIgnore, 'aaa');
    expect(upgrader.messages.buttonTitleLater, 'bbb');
    expect(upgrader.messages.buttonTitleUpdate, 'ccc');
    upgrader.dialogStyle = UpgradeDialogStyle.cupertino;

    await tester.pumpWidget(_MyWidget(upgrader_modeck: upgrader));

    expect(find.text('Upgrader test'), findsOneWidget);
    expect(find.text('Upgrading'), findsOneWidget);

    // Pump the UI so the upgrader_modeck can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), true);

    expect(find.text(upgrader.messages.title), findsOneWidget);
    expect(find.text(upgrader.message()), findsOneWidget);
    expect(find.text(upgrader.messages.releaseNotes), findsOneWidget);
    expect(find.text(upgrader.releaseNotes!), findsOneWidget);
    expect(find.text(upgrader.messages.prompt), findsOneWidget);
    expect(find.byType(CupertinoDialogAction), findsNWidgets(3));
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsOneWidget);
    expect(find.text(upgrader.messages.buttonTitleLater), findsOneWidget);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsOneWidget);

    await tester.tap(find.text(upgrader.messages.buttonTitleUpdate));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  }, skip: false);
  testWidgets('test UpgradeWidget ignore', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(platform: TargetPlatform.iOS, client: client, androidId: androidId, iosId: iosId);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onIgnore = () {
      called = true;
      return true;
    };
    upgrader.onUpdate = () {
      notCalled = false;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidget(upgrader_modeck: upgrader));

    // Pump the UI so the upgrader_modeck can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.messages.buttonTitleIgnore));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  }, skip: false);

  testWidgets('test UpgradeWidget later', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(platform: TargetPlatform.iOS, client: client, androidId: androidId, iosId: iosId);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onLater = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader.onUpdate = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidget(upgrader_modeck: upgrader));

    // Pump the UI so the upgrader_modeck can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.messages.buttonTitleLater));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  }, skip: false);

  testWidgets('test UpgradeWidget pop scope', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(platform: TargetPlatform.iOS, client: client, androidId: androidId, iosId: iosId);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    upgrader.shouldPopScope = () {
      called = true;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidget(upgrader_modeck: upgrader));

    // Pump the UI so the upgrader_modeck can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    // TODO: this test does not pop scope because there is no way to do that.
    // await tester.pageBack();
    // await tester.pumpAndSettle();
    // expect(find.text(upgrader_modeck.messages.buttonTitleLater), findsNothing);
    expect(called, false);
  }, skip: false);

  testWidgets('test UpgradeWidget Card upgrade', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true, androidId: androidId, iosId: iosId);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    expect(upgrader.messages, isNotNull);

    var called = false;
    var notCalled = true;
    upgrader.onUpdate = () {
      called = true;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard(upgrader_modeck: upgrader));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    expect(find.text(upgrader.messages.releaseNotes), findsOneWidget);
    expect(find.text(upgrader.releaseNotes!), findsOneWidget);
    await tester.tap(find.text(upgrader.messages.buttonTitleUpdate));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsNothing);
  }, skip: false);

  testWidgets('test UpgradeWidget Card ignore', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true, androidId: androidId, iosId: iosId);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onIgnore = () {
      called = true;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
      return true;
    };
    upgrader.onUpdate = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard(upgrader_modeck: upgrader));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.messages.buttonTitleIgnore));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
  }, skip: false);

  testWidgets('test UpgradeWidget Card later', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true, androidId: androidId, iosId: iosId);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onLater = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader.onUpdate = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard(upgrader_modeck: upgrader));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    await tester.tap(find.text(upgrader.messages.buttonTitleLater));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
  }, skip: false);

  testWidgets('test upgrader_modeck minAppVersion', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true, androidId: androidId, iosId: iosId);
    upgrader.minAppVersion = '1.0.0';

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    expect(upgrader.isTooSoon(), false);
    upgrader.minAppVersion = '0.5.0';
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = '1.0.0';
    expect(upgrader.belowMinAppVersion(), true);
    upgrader.minAppVersion = null;
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = 'empty';
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = '0.9.9+4';
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = '0.9.9-5.2.pre';
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = '1.0.0-5.2.pre';
    expect(upgrader.belowMinAppVersion(), true);

    upgrader.minAppVersion = '1.0.0';

    await tester.pumpWidget(_MyWidgetCard(upgrader_modeck: upgrader));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsOneWidget);
  }, skip: false);

  testWidgets('test upgrader_modeck minAppVersion description android',
      (WidgetTester tester) async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.android, client: client, debugLogging: true, androidId: androidId, iosId: iosId);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Money Friends',
            packageName: 'com.moneyfriends',
            version: '2.0.81',
            buildNumber: '139'));
    await upgrader.initialize();
    final belowMinAppVersion = upgrader.belowMinAppVersion();
    final minAppVersion = upgrader.minAppVersion;
    expect(belowMinAppVersion, true);
    expect(minAppVersion, '4.5.6');
  }, skip: false);

  testWidgets('test upgrader_modeck minAppVersion description ios',
      (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient(
      description: 'Use this app. [:mav: 4.5.6]',
    );
    final upgrader_modeck = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true, androidId: androidId, iosId: iosId);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '2.9.9',
            buildNumber: '400'));
    await upgrader_modeck.initialize();

    expect(upgrader_modeck.belowMinAppVersion(), true);
    expect(upgrader_modeck.minAppVersion, '4.5.6');
  }, skip: false);

  testWidgets('test UpgradeWidget unknown app', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(
        platform: TargetPlatform.iOS,
        client: client,
        debugLogging: true,
        countryCode: 'IT', androidId: androidId, iosId: iosId);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'MyApp',
            packageName: 'com.google.MyApp',
            version: '0.1.0',
            buildNumber: '1'));
    await upgrader_modeck.initialize();

    var called = false;
    var notCalled = true;
    upgrader_modeck.onLater = () {
      called = true;
      return true;
    };
    upgrader_modeck.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader_modeck.onUpdate = () {
      notCalled = false;
      return true;
    };

    expect(upgrader_modeck.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard(upgrader_modeck: upgrader_modeck));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    final laterButton = find.text(upgrader_modeck.messages.buttonTitleLater);
    expect(laterButton, findsNothing);

    expect(called, false);
    expect(notCalled, true);
  }, skip: false);

  group('initialize', () {
    test('should use fake Appcast', () async {
      final fakeAppcast = FakeAppcast();
      final client = MockITunesSearchClient.setupMockClient();
      final upgrader_modeck = Upgrader(
          platform: TargetPlatform.iOS,
          client: client,
          debugLogging: true,
          appcastConfig: fakeAppcast.config,
          appcast: fakeAppcast, androidId: androidId, iosId: iosId)
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '1.9.6',
            buildNumber: '42',
          ),
        );

      await upgrader_modeck.initialize();

      expect(fakeAppcast.callCount, greaterThan(0));
    }, skip: false);

    test('durationUntilAlertAgain defaults to 3 days', () async {
      final upgrader_modeck = Upgrader( androidId: androidId, iosId: iosId);
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(days: 3));
    }, skip: false);

    test('durationUntilAlertAgain is 0 days', () async {
      final upgrader_modeck =
          Upgrader(durationUntilAlertAgain: const Duration(seconds: 0), androidId: androidId, iosId: iosId);
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(seconds: 0));

      UpgradeAlert(upgrader: upgrader_modeck);
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(seconds: 0));

      UpgradeCard(upgrader_modeck: upgrader_modeck);
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(seconds: 0));
    }, skip: false);

    test('durationUntilAlertAgain card is valid', () async {
      final upgrader_modeck =
          Upgrader(durationUntilAlertAgain: const Duration(days: 3), androidId: androidId, iosId: iosId);
      UpgradeCard(upgrader_modeck: upgrader_modeck);
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(days: 3));

      final upgrader2 =
          Upgrader(durationUntilAlertAgain: const Duration(days: 10), androidId: androidId, iosId: iosId);
      final _ = UpgradeCard(upgrader_modeck: upgrader2);
      expect(upgrader2.durationUntilAlertAgain, const Duration(days: 10));
    }, skip: false);

    test('durationUntilAlertAgain alert is valid', () async {
      final upgrader_modeck =
          Upgrader(durationUntilAlertAgain: const Duration(days: 3), androidId: androidId, iosId: iosId);
      UpgradeAlert(upgrader: upgrader_modeck);
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(days: 3));

      final upgrader2 =
          Upgrader(durationUntilAlertAgain: const Duration(days: 10), androidId: androidId, iosId: iosId);
      UpgradeAlert(upgrader: upgrader2);
      expect(upgrader2.durationUntilAlertAgain, const Duration(days: 10));
    }, skip: false);
  });

  group('shouldDisplayUpgrade', () {
    test('should respect debugDisplayAlways property', () {
      final client = MockITunesSearchClient.setupMockClient();
      final upgrader_modeck = Upgrader(
          platform: TargetPlatform.iOS, client: client, debugLogging: true, androidId: androidId, iosId: iosId);

      expect(upgrader_modeck.shouldDisplayUpgrade(), false);
      upgrader_modeck.debugDisplayAlways = true;
      expect(upgrader_modeck.shouldDisplayUpgrade(), true);
      upgrader_modeck.debugDisplayAlways = false;
      expect(upgrader_modeck.shouldDisplayUpgrade(), false);

      // Test the willDisplayUpgrade callback
      var notCalled = true;
      upgrader_modeck.willDisplayUpgrade = (
          {required bool display,
          String? minAppVersion,
          String? installedVersion,
          String? appStoreVersion}) {
        expect(display, false);
        expect(minAppVersion, isNull);
        expect(installedVersion, isNull);
        expect(appStoreVersion, isNull);
        notCalled = false;
      };
      expect(upgrader_modeck.shouldDisplayUpgrade(), false);
      expect(notCalled, false);

      upgrader_modeck.debugDisplayAlways = true;
      notCalled = true;
      upgrader_modeck.willDisplayUpgrade = (
          {required bool display,
          String? minAppVersion,
          String? installedVersion,
          String? appStoreVersion}) {
        expect(display, true);
        expect(minAppVersion, isNull);
        expect(installedVersion, isNull);
        expect(appStoreVersion, isNull);
        notCalled = false;
      };
      expect(upgrader_modeck.shouldDisplayUpgrade(), true);
      expect(notCalled, false);
    }, skip: false);

    test('should return true when version is below minAppVersion', () async {
      final upgrader_modeck = Upgrader(
          debugLogging: true,
          platform: TargetPlatform.iOS,
          client: MockITunesSearchClient.setupMockClient(), androidId: androidId, iosId: iosId)
        ..minAppVersion = '2.0.0'
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '1.9.6',
            buildNumber: '42',
          ),
        );

      await upgrader_modeck.initialize();
      var notCalled = true;
      upgrader_modeck.willDisplayUpgrade = (
          {required bool display,
          String? minAppVersion,
          String? installedVersion,
          String? appStoreVersion}) {
        expect(display, true);
        expect(minAppVersion, '2.0.0');
        expect(upgrader_modeck.minAppVersion, '2.0.0');
        expect(installedVersion, '1.9.6');
        expect(appStoreVersion, '5.6');
        notCalled = false;
      };

      final shouldDisplayUpgrade = upgrader_modeck.shouldDisplayUpgrade();

      expect(shouldDisplayUpgrade, isTrue);
      expect(notCalled, false);
    }, skip: false);

    test('should return true when bestItem has critical update', () async {
      final upgrader_modeck = Upgrader(
          debugLogging: true,
          platform: TargetPlatform.iOS,
          client: MockITunesSearchClient.setupMockClient(), androidId: androidId, iosId: iosId)
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '2.0.0',
            buildNumber: '42',
          ),
        );

      await upgrader_modeck.initialize();

      final shouldDisplayUpgrade = upgrader_modeck.shouldDisplayUpgrade();

      expect(shouldDisplayUpgrade, isTrue);
    }, skip: false);

    test('packageInfo is empty', () async {
      final upgrader_modeck = Upgrader(
          client: MockITunesSearchClient.setupMockClient(),
          platform: TargetPlatform.iOS,
          debugLogging: true, androidId: androidId, iosId: iosId)
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: '',
            packageName: '',
            version: '',
            buildNumber: '',
          ),
        );

      await upgrader_modeck.initialize();
      expect(upgrader_modeck.shouldDisplayUpgrade(), isFalse);
      expect(upgrader_modeck.appName(), isEmpty);
      expect(upgrader_modeck.currentInstalledVersion(), isEmpty);
    }, skip: false);
  });

  test('test UpgraderMessages', () {
    verifyMessages(UpgraderMessages(code: 'en'), 'en');
    verifyMessages(UpgraderMessages(code: 'ar'), 'ar');
    verifyMessages(UpgraderMessages(code: 'bn'), 'bn');
    verifyMessages(UpgraderMessages(code: 'es'), 'es');
    verifyMessages(UpgraderMessages(code: 'fa'), 'fa');
    verifyMessages(UpgraderMessages(code: 'fil'), 'fil');
    verifyMessages(UpgraderMessages(code: 'fr'), 'fr');
    verifyMessages(UpgraderMessages(code: 'de'), 'de');
    verifyMessages(UpgraderMessages(code: 'el'), 'el');
    verifyMessages(UpgraderMessages(code: 'ht'), 'ht');
    verifyMessages(UpgraderMessages(code: 'hu'), 'hu');
    verifyMessages(UpgraderMessages(code: 'id'), 'id');
    verifyMessages(UpgraderMessages(code: 'it'), 'it');
    verifyMessages(UpgraderMessages(code: 'ja'), 'ja');
    verifyMessages(UpgraderMessages(code: 'kk'), 'kk');
    verifyMessages(UpgraderMessages(code: 'km'), 'km');
    verifyMessages(UpgraderMessages(code: 'ko'), 'ko');
    verifyMessages(UpgraderMessages(code: 'lt'), 'lt');
    verifyMessages(UpgraderMessages(code: 'mn'), 'mn');
    verifyMessages(UpgraderMessages(code: 'nb'), 'nb');
    verifyMessages(UpgraderMessages(code: 'nl'), 'nl');
    verifyMessages(UpgraderMessages(code: 'pt'), 'pt');
    verifyMessages(UpgraderMessages(code: 'pl'), 'pl');
    verifyMessages(UpgraderMessages(code: 'ru'), 'ru');
    verifyMessages(UpgraderMessages(code: 'sv'), 'sv');
    verifyMessages(UpgraderMessages(code: 'ta'), 'ta');
    verifyMessages(UpgraderMessages(code: 'tr'), 'tr');
    verifyMessages(UpgraderMessages(code: 'uk'), 'uk');
    verifyMessages(UpgraderMessages(code: 'vi'), 'vi');
  }, skip: false);
}

void verifyMessages(UpgraderMessages messages, String code) {
  expect(messages.languageCode, code);
  expect(messages.message(UpgraderMessage.body)!.isNotEmpty, isTrue);
  expect(
      messages.message(UpgraderMessage.buttonTitleIgnore)!.isNotEmpty, isTrue);
  expect(
      messages.message(UpgraderMessage.buttonTitleLater)!.isNotEmpty, isTrue);
  expect(
      messages.message(UpgraderMessage.buttonTitleUpdate)!.isNotEmpty, isTrue);
  expect(messages.message(UpgraderMessage.prompt)!.isNotEmpty, isTrue);
  expect(messages.message(UpgraderMessage.title)!.isNotEmpty, isTrue);
}

class _MyWidget extends StatelessWidget {
  final Upgrader upgrader_modeck;
  const _MyWidget({Key? key, required this.upgrader_modeck}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Upgrader test'),
        ),
        body: UpgradeAlert(
            upgrader: upgrader_modeck,
            child: Column(
              children: const <Widget>[Text('Upgrading')],
            )),
      ),
    );
  }
}

class _MyWidgetCard extends StatelessWidget {
  final Upgrader upgrader_modeck;
  const _MyWidgetCard({Key? key, required this.upgrader_modeck}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Upgrader test'),
        ),
        body: Column(
          children: <Widget>[UpgradeCard(upgrader_modeck: upgrader_modeck)],
        ),
      ),
    );
  }
}

class MyUpgraderMessages extends UpgraderMessages {
  @override
  String get buttonTitleIgnore => 'aaa';
  @override
  String get buttonTitleLater => 'bbb';
  @override
  String get buttonTitleUpdate => 'ccc';
  @override
  String get releaseNotes => 'ddd';
}
