/*
 * Copyright (c) 2019-2022 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:upgrader_modeck/upgrader_modeck.dart';
import 'package:version/version.dart';

import 'mock_play_store_client.dart';

/// Helper method
String? pmav(Document response, {String tagName = 'mav'}) {
  final mav = PlayStoreResults.minAppVersion(response, tagName: tagName);
  return mav?.toString();
}

void main() {
  test('testing version assumptions', () async {
    expect(() => Version.parse(''), throwsA(isA<FormatException>()));
    expect(() => Version.parse('Varies with device'),
        throwsA(isA<FormatException>()));

    expect(Version.parse('1.2.3').toString(), '1.2.3');
    expect(Version.parse('1.2.3+1').toString(), '1.2.3+1');
    expect(Version.parse('0.0.0').toString(), '0.0.0');
    expect(Version.parse('0.0.0+1').toString(), '0.0.0+1');
  }, skip: false);

  test('testing PlayStoreSearchAPI properties', () async {
    final playStore = PlayStoreSearchAPI();
    expect(playStore.debugEnabled, equals(false));
    playStore.debugEnabled = true;
    expect(playStore.debugEnabled, equals(true));
    expect(playStore.playStorePrefixURL.length, greaterThan(0));

    expect(
        playStore.lookupURLById('com.kotoko.express'),
        startsWith(
            'https://play.google.com/store/apps/details?id=com.kotoko.express&gl=US&_cb='));
  }, skip: false);

  test('testing lookupById', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);
    expect(() async => await playStore.lookupById(''), throwsAssertionError);

    final response = await playStore.lookupById('com.kotoko.express');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(PlayStoreResults.releaseNotes(response!),
        'Minor updates and improvements.');
    expect(PlayStoreResults.version(response), '1.23.0');

    expect(await playStore.lookupById('com.not.a.valid.application'), isNull);

    final document1 = await playStore.lookupById('com.testing.test4');
    expect(document1, isNotNull);
    expect(document1, isInstanceOf<Document>());

    final document2 =
        await playStore.lookupById('com.testing.test4', country: 'JP');
    expect(document2, isNull);
    final document3 =
        await playStore.lookupById('com.testing.test4', useCacheBuster: false);
    expect(document3, isNotNull);
  }, skip: false);

  test('testing lookupURLById', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);
    expect(() => playStore.lookupURLById(''), throwsAssertionError);
    expect(
        playStore.lookupURLById('com.testing.test1')!.startsWith(
            'https://play.google.com/store/apps/details?id=com.testing.test1&gl=US&_cb=16'),
        equals(true));
    expect(
        playStore.lookupURLById('com.testing.test1', country: null)!.startsWith(
            'https://play.google.com/store/apps/details?id=com.testing.test1&_cb=16'),
        equals(true));
    expect(
        playStore.lookupURLById('com.testing.test1', country: '')!.startsWith(
            'https://play.google.com/store/apps/details?id=com.testing.test1&_cb=16'),
        equals(true));
    expect(
        playStore.lookupURLById('com.testing.test1', country: 'IN')!.startsWith(
            'https://play.google.com/store/apps/details?id=com.testing.test1&gl=IN&_cb=16'),
        equals(true));
    expect(
        playStore
            .lookupURLById('com.testing.test1',
                country: 'IN', useCacheBuster: false)!
            .startsWith(
                'https://play.google.com/store/apps/details?id=com.testing.test1&gl=IN'),
        equals(true));
  }, skip: false);

  test('testing lookupById with redesignedVersion', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);

    final response = await playStore.lookupById('com.testing.test4');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(PlayStoreResults.releaseNotes(response!),
        'Minor updates and improvements.');
    expect(PlayStoreResults.version(response), '2.3.0');
    expect(PlayStoreResults.description(response)?.length, greaterThan(10));
    expect(pmav(response), '2.0.0');

    expect(await playStore.lookupById('com.not.a.valid.application'), isNull);
  }, skip: false);

  test('testing release notes', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);

    final response = await playStore.lookupById('com.testing.test2');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(PlayStoreResults.releaseNotes(response!),
        'Minor updates and improvements.');
    expect(PlayStoreResults.version(response), '2.0.2');
    expect(PlayStoreResults.description(response)?.length, greaterThan(10));
  }, skip: false);

  test('testing release notes <br>', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);

    final response = await playStore.lookupById('com.testing.test3');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(PlayStoreResults.releaseNotes(response!),
        'Minor updates and improvements.\nAgain.\nAgain.');
    expect(PlayStoreResults.version(response), '2.0.2');
    expect(PlayStoreResults.description(response)?.length, greaterThan(10));
  }, skip: false);

  test('testing PlayStoreResults', () async {
    expect(PlayStoreResults(), isNotNull);
    expect(PlayStoreResults.releaseNotes(Document()), isNull);
    expect(PlayStoreResults.version(Document()), isNull);
  }, skip: false);

  /// Helper method
  Document resDesc(String description) {
    final html =
        '<div class="W4P4ne">hello<div class="PHBdkd">inside<div class="DWPxHb">$description</div></div></div>';
    return Document.html(html);
  }

  test('testing minAppVersion', () async {
    expect(pmav(resDesc('test [:mav: 1.2.3]')), '1.2.3');
    expect(pmav(resDesc('test [:mav:1.2.3]')), '1.2.3');
    expect(pmav(resDesc('test [:mav:1.2.3 ]')), '1.2.3');
    expect(pmav(resDesc('test [:mav: 1]')), '1.0.0');
    expect(pmav(resDesc('[:mav: 0.9.9+4]')), '0.9.9+4');
    expect(pmav(resDesc('[:mav: 1.0.0-5.2.pre]')), '1.0.0-5.2.pre');
    expect(pmav(Document()), isNull);
    expect(pmav(resDesc('test')), isNull);
    expect(pmav(resDesc('test [:mav:]')), isNull);
    expect(pmav(resDesc('test [:mv: 1.2.3]')), isNull);
  }, skip: false);

  test('testing minAppVersion mav tag', () async {
    expect(pmav(resDesc('test [:mav: 1.2.3]'), tagName: 'ddd'), isNull);
    expect(pmav(resDesc('test [:ddd: 1.2.3]'), tagName: 'ddd'), '1.2.3');
  });
}
