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

  testWidgets('test Upgrader sharedInstance', (WidgetTester tester) async {
    final upgrader1 = Upgrader.sharedInstance;
    expect(upgrader1, isNotNull);
    final upgrader2 = Upgrader.sharedInstance;
    expect(upgrader2, isNotNull);
    expect(upgrader1 == upgrader2, isTrue);
  }, skip: false);

  testWidgets('test Upgrader class', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(platform: TargetPlatform.iOS, client: client);

    expect(tester.takeException(), null);
    await tester.pumpAndSettle();
    try {
      expect(upgrader_modeck.appName(), 'Upgrader');
    } catch (e) {
      expect(e, upgrader_modeck.notInitializedExceptionMessage);
    }

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '1.9.9',
            buildNumber: '400'));
    await upgrader_modeck.initialize();

    // Calling initialize() a second time should do nothing
    await upgrader_modeck.initialize();

    expect(upgrader_modeck.appName(), 'Upgrader');
    expect(upgrader_modeck.currentAppStoreVersion(), '5.6');
    expect(upgrader_modeck.currentInstalledVersion(), '1.9.9');
    expect(upgrader_modeck.isUpdateAvailable(), true);

    upgrader_modeck.installAppStoreVersion('1.2.3');
    expect(upgrader_modeck.currentAppStoreVersion(), '1.2.3');
  }, skip: false);

  testWidgets('test installAppStoreListingURL', (WidgetTester tester) async {
    final upgrader_modeck = Upgrader();
    upgrader_modeck.installAppStoreListingURL(
        'https://itunes.apple.com/us/app/google-maps-transit-food/id585027354?mt=8&uo=4');

    expect(upgrader_modeck.currentAppStoreListingURL(),
        'https://itunes.apple.com/us/app/google-maps-transit-food/id585027354?mt=8&uo=4');
  }, skip: false);

  testWidgets('test UpgradeWidget', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader_modeck.initialize();

    var called = false;
    var notCalled = true;
    upgrader_modeck.onUpdate = () {
      called = true;
      return true;
    };
    upgrader_modeck.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader_modeck.onLater = () {
      notCalled = false;
      return true;
    };

    expect(upgrader_modeck.isUpdateAvailable(), true);
    expect(upgrader_modeck.isTooSoon(), false);

    expect(upgrader_modeck.messages, isNotNull);

    expect(upgrader_modeck.messages.buttonTitleIgnore, 'IGNORE');
    expect(upgrader_modeck.messages.buttonTitleLater, 'LATER');
    expect(upgrader_modeck.messages.buttonTitleUpdate, 'UPDATE NOW');
    expect(upgrader_modeck.messages.releaseNotes, 'Release Notes');

    upgrader_modeck.messages = MyUpgraderMessages();

    expect(upgrader_modeck.messages.buttonTitleIgnore, 'aaa');
    expect(upgrader_modeck.messages.buttonTitleLater, 'bbb');
    expect(upgrader_modeck.messages.buttonTitleUpdate, 'ccc');
    expect(upgrader_modeck.messages.releaseNotes, 'ddd');

    await tester.pumpWidget(_MyWidget(upgrader_modeck: upgrader_modeck));

    expect(find.text('Upgrader test'), findsOneWidget);
    expect(find.text('Upgrading'), findsOneWidget);

    // Pump the UI so the upgrader_modeck can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(upgrader_modeck.isTooSoon(), true);

    expect(find.text(upgrader_modeck.messages.title), findsOneWidget);
    expect(find.text(upgrader_modeck.message()), findsOneWidget);
    expect(find.text(upgrader_modeck.messages.releaseNotes), findsOneWidget);
    expect(find.text(upgrader_modeck.releaseNotes!), findsOneWidget);
    expect(find.text(upgrader_modeck.messages.prompt), findsOneWidget);
    expect(find.byType(TextButton), findsNWidgets(3));
    expect(find.text(upgrader_modeck.messages.buttonTitleIgnore), findsOneWidget);
    expect(find.text(upgrader_modeck.messages.buttonTitleLater), findsOneWidget);
    expect(find.text(upgrader_modeck.messages.buttonTitleUpdate), findsOneWidget);
    expect(find.text(upgrader_modeck.messages.releaseNotes), findsOneWidget);

    await tester.tap(find.text(upgrader_modeck.messages.buttonTitleUpdate));
    await tester.pumpAndSettle();
    expect(find.text(upgrader_modeck.messages.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader_modeck.messages.buttonTitleLater), findsNothing);
    expect(find.text(upgrader_modeck.messages.buttonTitleUpdate), findsNothing);
    expect(find.text(upgrader_modeck.messages.releaseNotes), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  }, skip: false);

  testWidgets('test UpgradeWidget Cupertino', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader_modeck.initialize();

    var called = false;
    var notCalled = true;
    upgrader_modeck.onUpdate = () {
      called = true;
      return true;
    };
    upgrader_modeck.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader_modeck.onLater = () {
      notCalled = false;
      return true;
    };

    expect(upgrader_modeck.isUpdateAvailable(), true);
    expect(upgrader_modeck.isTooSoon(), false);

    expect(upgrader_modeck.messages, isNotNull);

    expect(upgrader_modeck.messages.buttonTitleIgnore, 'IGNORE');
    expect(upgrader_modeck.messages.buttonTitleLater, 'LATER');
    expect(upgrader_modeck.messages.buttonTitleUpdate, 'UPDATE NOW');

    upgrader_modeck.messages = MyUpgraderMessages();

    expect(upgrader_modeck.messages.buttonTitleIgnore, 'aaa');
    expect(upgrader_modeck.messages.buttonTitleLater, 'bbb');
    expect(upgrader_modeck.messages.buttonTitleUpdate, 'ccc');
    upgrader_modeck.dialogStyle = UpgradeDialogStyle.cupertino;

    await tester.pumpWidget(_MyWidget(upgrader_modeck: upgrader_modeck));

    expect(find.text('Upgrader test'), findsOneWidget);
    expect(find.text('Upgrading'), findsOneWidget);

    // Pump the UI so the upgrader_modeck can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(upgrader_modeck.isTooSoon(), true);

    expect(find.text(upgrader_modeck.messages.title), findsOneWidget);
    expect(find.text(upgrader_modeck.message()), findsOneWidget);
    expect(find.text(upgrader_modeck.messages.releaseNotes), findsOneWidget);
    expect(find.text(upgrader_modeck.releaseNotes!), findsOneWidget);
    expect(find.text(upgrader_modeck.messages.prompt), findsOneWidget);
    expect(find.byType(CupertinoDialogAction), findsNWidgets(3));
    expect(find.text(upgrader_modeck.messages.buttonTitleIgnore), findsOneWidget);
    expect(find.text(upgrader_modeck.messages.buttonTitleLater), findsOneWidget);
    expect(find.text(upgrader_modeck.messages.buttonTitleUpdate), findsOneWidget);

    await tester.tap(find.text(upgrader_modeck.messages.buttonTitleUpdate));
    await tester.pumpAndSettle();
    expect(find.text(upgrader_modeck.messages.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader_modeck.messages.buttonTitleLater), findsNothing);
    expect(find.text(upgrader_modeck.messages.buttonTitleUpdate), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  }, skip: false);
  testWidgets('test UpgradeWidget ignore', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(platform: TargetPlatform.iOS, client: client);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader_modeck.initialize();

    var called = false;
    var notCalled = true;
    upgrader_modeck.onIgnore = () {
      called = true;
      return true;
    };
    upgrader_modeck.onUpdate = () {
      notCalled = false;
      return true;
    };
    upgrader_modeck.onLater = () {
      notCalled = false;
      return true;
    };

    expect(upgrader_modeck.isTooSoon(), false);

    await tester.pumpWidget(_MyWidget(upgrader_modeck: upgrader_modeck));

    // Pump the UI so the upgrader_modeck can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader_modeck.messages.buttonTitleIgnore));
    await tester.pumpAndSettle();
    expect(find.text(upgrader_modeck.messages.buttonTitleIgnore), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  }, skip: false);

  testWidgets('test UpgradeWidget later', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(platform: TargetPlatform.iOS, client: client);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '0.9.9',
            buildNumber: '400'));
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

    await tester.pumpWidget(_MyWidget(upgrader_modeck: upgrader_modeck));

    // Pump the UI so the upgrader_modeck can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader_modeck.messages.buttonTitleLater));
    await tester.pumpAndSettle();
    expect(find.text(upgrader_modeck.messages.buttonTitleLater), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  }, skip: false);

  testWidgets('test UpgradeWidget pop scope', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(platform: TargetPlatform.iOS, client: client);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader_modeck.initialize();

    var called = false;
    upgrader_modeck.shouldPopScope = () {
      called = true;
      return true;
    };

    expect(upgrader_modeck.isTooSoon(), false);

    await tester.pumpWidget(_MyWidget(upgrader_modeck: upgrader_modeck));

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
    final upgrader_modeck = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader_modeck.initialize();

    expect(upgrader_modeck.messages, isNotNull);

    var called = false;
    var notCalled = true;
    upgrader_modeck.onUpdate = () {
      called = true;
      return true;
    };
    upgrader_modeck.onLater = () {
      notCalled = false;
      return true;
    };
    upgrader_modeck.onIgnore = () {
      notCalled = false;
      return true;
    };

    expect(upgrader_modeck.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard(upgrader_modeck: upgrader_modeck));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    expect(find.text(upgrader_modeck.messages.releaseNotes), findsOneWidget);
    expect(find.text(upgrader_modeck.releaseNotes!), findsOneWidget);
    await tester.tap(find.text(upgrader_modeck.messages.buttonTitleUpdate));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader_modeck.messages.buttonTitleUpdate), findsNothing);
  }, skip: false);

  testWidgets('test UpgradeWidget Card ignore', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader_modeck.initialize();

    var called = false;
    var notCalled = true;
    upgrader_modeck.onIgnore = () {
      called = true;
      return true;
    };
    upgrader_modeck.onLater = () {
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

    await tester.tap(find.text(upgrader_modeck.messages.buttonTitleIgnore));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader_modeck.messages.buttonTitleIgnore), findsNothing);
  }, skip: false);

  testWidgets('test UpgradeWidget Card later', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '0.9.9',
            buildNumber: '400'));
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
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    await tester.tap(find.text(upgrader_modeck.messages.buttonTitleLater));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader_modeck.messages.buttonTitleLater), findsNothing);
  }, skip: false);

  testWidgets('test upgrader_modeck minAppVersion', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);
    upgrader_modeck.minAppVersion = '1.0.0';

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader_modeck.initialize();

    expect(upgrader_modeck.isTooSoon(), false);
    upgrader_modeck.minAppVersion = '0.5.0';
    expect(upgrader_modeck.belowMinAppVersion(), false);
    upgrader_modeck.minAppVersion = '1.0.0';
    expect(upgrader_modeck.belowMinAppVersion(), true);
    upgrader_modeck.minAppVersion = null;
    expect(upgrader_modeck.belowMinAppVersion(), false);
    upgrader_modeck.minAppVersion = 'empty';
    expect(upgrader_modeck.belowMinAppVersion(), false);
    upgrader_modeck.minAppVersion = '0.9.9+4';
    expect(upgrader_modeck.belowMinAppVersion(), false);
    upgrader_modeck.minAppVersion = '0.9.9-5.2.pre';
    expect(upgrader_modeck.belowMinAppVersion(), false);
    upgrader_modeck.minAppVersion = '1.0.0-5.2.pre';
    expect(upgrader_modeck.belowMinAppVersion(), true);

    upgrader_modeck.minAppVersion = '1.0.0';

    await tester.pumpWidget(_MyWidgetCard(upgrader_modeck: upgrader_modeck));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    expect(find.text(upgrader_modeck.messages.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader_modeck.messages.buttonTitleLater), findsNothing);
    expect(find.text(upgrader_modeck.messages.buttonTitleUpdate), findsOneWidget);
  }, skip: false);

  testWidgets('test upgrader_modeck minAppVersion description android',
      (WidgetTester tester) async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final upgrader_modeck = Upgrader(
        platform: TargetPlatform.android, client: client, debugLogging: true);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.testing.test2',
            version: '2.9.9',
            buildNumber: '400'));
    await upgrader_modeck.initialize();

    expect(upgrader_modeck.belowMinAppVersion(), true);
    expect(upgrader_modeck.minAppVersion, '4.5.6');
  }, skip: false);

  testWidgets('test upgrader_modeck minAppVersion description ios',
      (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient(
      description: 'Use this app. [:mav: 4.5.6]',
    );
    final upgrader_modeck = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader_modeck.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
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
        countryCode: 'IT');

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
          appcast: fakeAppcast)
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
            version: '1.9.6',
            buildNumber: '42',
          ),
        );

      await upgrader_modeck.initialize();

      expect(fakeAppcast.callCount, greaterThan(0));
    }, skip: false);

    test('durationUntilAlertAgain defaults to 3 days', () async {
      final upgrader_modeck = Upgrader();
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(days: 3));
    }, skip: false);

    test('durationUntilAlertAgain is 0 days', () async {
      final upgrader_modeck =
          Upgrader(durationUntilAlertAgain: const Duration(seconds: 0));
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(seconds: 0));

      UpgradeAlert(upgrader_modeck: upgrader_modeck);
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(seconds: 0));

      UpgradeCard(upgrader_modeck: upgrader_modeck);
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(seconds: 0));
    }, skip: false);

    test('durationUntilAlertAgain card is valid', () async {
      final upgrader_modeck =
          Upgrader(durationUntilAlertAgain: const Duration(days: 3));
      UpgradeCard(upgrader_modeck: upgrader_modeck);
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(days: 3));

      final upgrader2 =
          Upgrader(durationUntilAlertAgain: const Duration(days: 10));
      final _ = UpgradeCard(upgrader_modeck: upgrader2);
      expect(upgrader2.durationUntilAlertAgain, const Duration(days: 10));
    }, skip: false);

    test('durationUntilAlertAgain alert is valid', () async {
      final upgrader_modeck =
          Upgrader(durationUntilAlertAgain: const Duration(days: 3));
      UpgradeAlert(upgrader_modeck: upgrader_modeck);
      expect(upgrader_modeck.durationUntilAlertAgain, const Duration(days: 3));

      final upgrader2 =
          Upgrader(durationUntilAlertAgain: const Duration(days: 10));
      UpgradeAlert(upgrader_modeck: upgrader2);
      expect(upgrader2.durationUntilAlertAgain, const Duration(days: 10));
    }, skip: false);
  });

  group('shouldDisplayUpgrade', () {
    test('should respect debugDisplayAlways property', () {
      final client = MockITunesSearchClient.setupMockClient();
      final upgrader_modeck = Upgrader(
          platform: TargetPlatform.iOS, client: client, debugLogging: true);

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
          client: MockITunesSearchClient.setupMockClient())
        ..minAppVersion = '2.0.0'
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
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
          client: MockITunesSearchClient.setupMockClient())
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader_modeck',
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
          debugLogging: true)
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
            upgrader_modeck: upgrader_modeck,
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
