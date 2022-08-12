/*
 * Copyright (c) 2021-2022 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader_modeck/upgrader_modeck.dart';

/// A widget to display the upgrade dialog.
class UpgradeAlert extends UpgradeBase {
  /// The [child] contained by the widget.
  final Widget? child;

  /// Creates a new [UpgradeAlert].
  UpgradeAlert({Key? key, required Upgrader upgrader, this.child})
      : super(upgrader, key: key);

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context, UpgradeBaseState state) {
    if (upgrader.debugLogging) {
      print('upgrader_modeck: build UpgradeAlert');
    }

    return FutureBuilder(
        future: state.initialized,
        builder: (BuildContext context, AsyncSnapshot<bool> processed) {
          if (processed.connectionState == ConnectionState.done &&
              processed.data != null &&
              processed.data!) {
            upgrader.checkVersion(context: context);
          }
          return child ?? Container();
        });
  }
}
