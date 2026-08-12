import 'package:flutter/material.dart';

const double adminWebLayoutBreakpoint = 900;

bool useAdminWebLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= adminWebLayoutBreakpoint;
}

class AdminPageFrame extends StatelessWidget {
  const AdminPageFrame({super.key, required this.child, this.maxWidth = 1120});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!useAdminWebLayout(context)) {
      return child;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth < 1480 ? 1480 : maxWidth,
        ),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
