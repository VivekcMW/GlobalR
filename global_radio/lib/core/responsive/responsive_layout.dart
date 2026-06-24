/// Responsive layout utilities for tablet and various screen sizes.
///
/// Provides:
/// - Screen size breakpoints
/// - Responsive builders
/// - Adaptive layouts for phone/tablet
library;

import 'package:flutter/material.dart';

/// Screen size breakpoints.
class Breakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  Breakpoints._();
}

/// Screen type based on width.
enum ScreenType {
  phone,
  tablet,
  desktop,
}

/// Get the current screen type.
ScreenType getScreenType(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < Breakpoints.phone) {
    return ScreenType.phone;
  } else if (width < Breakpoints.tablet) {
    return ScreenType.tablet;
  } else {
    return ScreenType.desktop;
  }
}

/// Extension for easy screen type access.
extension ResponsiveContext on BuildContext {
  ScreenType get screenType => getScreenType(this);
  bool get isPhone => screenType == ScreenType.phone;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;
  bool get isWide => !isPhone;
  
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  
  /// Get responsive padding based on screen size.
  EdgeInsets get responsivePadding {
    if (isPhone) {
      return const EdgeInsets.all(16);
    } else if (isTablet) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }
  
  /// Get max content width for large screens.
  double get maxContentWidth {
    if (isPhone) return double.infinity;
    if (isTablet) return 700;
    return 900;
  }
}

/// Responsive builder that adapts to screen size.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, context.screenType);
  }
}

/// Shows different widgets for phone vs tablet.
class ResponsiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    
    switch (screenType) {
      case ScreenType.desktop:
        return desktop ?? tablet ?? phone;
      case ScreenType.tablet:
        return tablet ?? phone;
      case ScreenType.phone:
        return phone;
    }
  }
}

/// Adaptive scaffold with optional side navigation for tablets.
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? sideNavigation;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.sideNavigation,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = context.isWide;

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      body: isWide && sideNavigation != null
          ? Row(
              children: [
                sideNavigation!,
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide ? null : bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Responsive grid that adjusts column count.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int phoneColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.phoneColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.spacing = 16,
    this.runSpacing = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final columns = switch (context.screenType) {
      ScreenType.phone => phoneColumns,
      ScreenType.tablet => tabletColumns,
      ScreenType.desktop => desktopColumns,
    };

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// Content wrapper that centers and constrains width on large screens.
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.maxContentWidth,
        ),
        child: Padding(
          padding: padding ?? context.responsivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Adaptive column count for sliver grids.
int getAdaptiveColumnCount(BuildContext context, {
  int phoneColumns = 2,
  int tabletColumns = 3,
  int desktopColumns = 4,
}) {
  return switch (context.screenType) {
    ScreenType.phone => phoneColumns,
    ScreenType.tablet => tabletColumns,
    ScreenType.desktop => desktopColumns,
  };
}

/// Adaptive icon size.
double getAdaptiveIconSize(BuildContext context, {
  double phoneSize = 24,
  double tabletSize = 28,
  double desktopSize = 32,
}) {
  return switch (context.screenType) {
    ScreenType.phone => phoneSize,
    ScreenType.tablet => tabletSize,
    ScreenType.desktop => desktopSize,
  };
}

/// Master-detail layout for tablets.
class MasterDetailLayout extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final Widget emptyDetail;
  final double masterWidth;

  const MasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.emptyDetail = const Center(child: Text('Select an item')),
    this.masterWidth = 350,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isPhone) {
      // On phone, show only master (navigation handles detail)
      return master;
    }

    // On tablet/desktop, show side-by-side
    return Row(
      children: [
        SizedBox(
          width: masterWidth,
          child: master,
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: detail ?? emptyDetail,
        ),
      ],
    );
  }
}
