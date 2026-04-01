import 'package:flutter/cupertino.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'extensions/context_extensions.dart';

class SpinKitIndicator {
  const SpinKitIndicator._();

  static SpinKitChasingDots primaryColored(BuildContext context, {double? size}) {
    return SpinKitChasingDots(size: size ?? 50, color: context.colorScheme.primary);
  }

  static SpinKitChasingDots onPrimaryColored(
    BuildContext context, {
    double? size,
  }) {
    return SpinKitChasingDots(size: size ?? 50, color: context.colorScheme.onPrimary);
  }
}
