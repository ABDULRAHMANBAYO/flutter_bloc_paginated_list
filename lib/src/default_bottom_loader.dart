import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The default "loading more" indicator shown at the bottom of the list while
/// the next page is being fetched.
///
/// Renders a platform-appropriate spinner: a [CupertinoActivityIndicator] on
/// iOS and a [CircularProgressIndicator] elsewhere. The Material spinner is
/// tinted with [color], falling back to the theme's primary color.
class DefaultBottomLoader extends StatelessWidget {
  const DefaultBottomLoader({super.key, this.color});

  /// Tint for the Material [CircularProgressIndicator]. Defaults to the theme's
  /// primary color when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Theme.of(context).platform == TargetPlatform.iOS
            ? const CupertinoActivityIndicator()
            : CircularProgressIndicator(color: resolvedColor),
      ),
    );
  }
}
