/*
 * Copyright (c) 2021-2022 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader_modeck/upgrader_modeck.dart';

/// A widget to display the upgrade card.
class UpgradeCard extends UpgradeBase {
  /// The empty space that surrounds the card.
  ///
  /// The default margin is 4.0 logical pixels on all sides:
  /// `EdgeInsets.all(4.0)`.
  final EdgeInsetsGeometry margin;

  /// Creates a new [UpgradeCard].
  UpgradeCard(
      {Key? key, Upgrader? upgrader_modeck, this.margin = const EdgeInsets.all(4.0)})
      : super(upgrader_modeck ?? Upgrader.sharedInstance, key: key);

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context, UpgradeBaseState state) {
    if (upgrader_modeck.debugLogging) {
      print('UpgradeCard: build UpgradeCard');
    }

    return FutureBuilder(
        future: state.initialized,
        builder: (BuildContext context, AsyncSnapshot<bool> processed) {
          if (processed.connectionState == ConnectionState.done &&
              processed.data != null &&
              processed.data!) {
            if (upgrader_modeck.shouldDisplayUpgrade()) {
              final title = upgrader_modeck.messages.message(UpgraderMessage.title);
              final message = upgrader_modeck.message();
              final releaseNotes = upgrader_modeck.releaseNotes;
              final shouldDisplayReleaseNotes =
                  upgrader_modeck.shouldDisplayReleaseNotes();
              if (upgrader_modeck.debugLogging) {
                print('UpgradeCard: will display');
                print('UpgradeCard: showDialog title: $title');
                print('UpgradeCard: showDialog message: $message');
                print(
                    'UpgradeCard: shouldDisplayReleaseNotes: $shouldDisplayReleaseNotes');

                print('UpgradeCard: showDialog releaseNotes: $releaseNotes');
              }

              Widget? notes;
              if (shouldDisplayReleaseNotes && releaseNotes != null) {
                notes = Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                            Upgrader()
                                    .messages
                                    .message(UpgraderMessage.releaseNotes) ??
                                '',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          releaseNotes,
                          maxLines: 15,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ));
              }

              return Card(
                  color: Colors.white,
                  margin: margin,
                  child: AlertStyleWidget(
                      title: Text(title ?? ''),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(message),
                          Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: Text(upgrader_modeck.messages
                                      .message(UpgraderMessage.prompt) ??
                                  '')),
                          if (notes != null) notes,
                        ],
                      ),
                      actions: <Widget>[
                        if (upgrader_modeck.showIgnore)
                          TextButton(
                              child: Text(upgrader_modeck.messages.message(
                                      UpgraderMessage.buttonTitleIgnore) ??
                                  ''),
                              onPressed: () {
                                // Save the date/time as the last time alerted.
                                upgrader_modeck.saveLastAlerted();

                                upgrader_modeck.onUserIgnored(context, false);
                                state.forceUpdateState();
                              }),
                        if (upgrader_modeck.showLater)
                          TextButton(
                              child: Text(upgrader_modeck.messages.message(
                                      UpgraderMessage.buttonTitleLater) ??
                                  ''),
                              onPressed: () {
                                // Save the date/time as the last time alerted.
                                upgrader_modeck.saveLastAlerted();

                                upgrader_modeck.onUserLater(context, false);
                                state.forceUpdateState();
                              }),
                        TextButton(
                            child: Text(upgrader_modeck.messages.message(
                                    UpgraderMessage.buttonTitleUpdate) ??
                                ''),
                            onPressed: () {
                              // Save the date/time as the last time alerted.
                              upgrader_modeck.saveLastAlerted();

                              upgrader_modeck.onUserUpdated(context, false);
                              state.forceUpdateState();
                            }),
                      ]));
            } else {
              if (upgrader_modeck.debugLogging) {
                print('UpgradeCard: will not display');
              }
            }
          }
          return const SizedBox(width: 0.0, height: 0.0);
        });
  }
}
