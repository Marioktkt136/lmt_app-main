import 'package:material_ui/material_ui.dart';

/// Responsive width breakpoints following Material 3 adaptive layout guidelines.
class AdaptiveBreakpoints {
  AdaptiveBreakpoints._();

  /// Width below which layouts use a single-column compact mobile structure.
  static const double compactMaxWidth = 600.0;

  /// Width at or above which navigation switches from bottom bar to side rail.
  static const double navRailMinWidth = 680.0;

  /// Width at or above which the side navigation rail shows extended labels.
  static const double navRailExtendedMinWidth = 980.0;

  /// Width at or above which master-detail split views activate on desktop/web.
  static const double desktopSplitMinWidth = 960.0;

  /// Maximum width for wide desktop multi-column views (Calendar, Files, Members).
  static const double wideDesktopMaxWidth = 1140.0;

  /// Maximum readable content width for feed, forms, settings, and profile views.
  static const double readableMaxWidth = 740.0;

  /// Maximum width for modal bottom sheets on wide tablets and desktop windows.
  static const double sheetMaxWidth = 580.0;

  /// Returns `true` when [width] is wider than a standard phone portrait screen.
  static bool isMediumOrLarger(double width) => width >= compactMaxWidth;

  /// Returns the number of grid columns suited to [width].
  static int gridColumnsForWidth(
    double width, {
    int compact = 1,
    int medium = 2,
    int expanded = 3,
  }) {
    if (width >= 960) return expanded;
    if (width >= compactMaxWidth) return medium;
    return compact;
  }

  /// Returns modal sheet constraints keeping sheets centered on tablets.
  static BoxConstraints bottomSheetConstraints(
    BuildContext context, {
    double maxWidth = sheetMaxWidth,
  }) {
    return BoxConstraints(
      maxWidth: maxWidth,
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
    );
  }
}

/// Centers [child] within a maximum horizontal constraint on wide screens
/// while occupying full width on compact mobile viewports.
class AdaptiveContentBox extends StatelessWidget {
  /// The content widget to constrain horizontally.
  final Widget child;

  /// Maximum width allowed for [child].
  final double maxWidth;

  /// Creates an [AdaptiveContentBox].
  const AdaptiveContentBox({
    super.key,
    required this.child,
    this.maxWidth = AdaptiveBreakpoints.readableMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxWidth,
            child: child,
          ),
        );
      },
    );
  }
}
