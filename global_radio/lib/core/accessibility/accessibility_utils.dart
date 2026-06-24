/// Accessibility utilities and semantic wrapper widgets.
///
/// Provides consistent accessibility support across the app with proper
/// semantic labels, hints, and announcements for screen readers.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Semantic wrapper for interactive elements with proper accessibility labels.
class SemanticButton extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isButton;

  const SemanticButton({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
    this.enabled = true,
    this.isButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      child: child,
    );
  }
}

/// Semantic wrapper for images with proper alt text.
class SemanticImage extends StatelessWidget {
  final Widget child;
  final String label;
  final bool excludeFromSemantics;

  const SemanticImage({
    super.key,
    required this.child,
    required this.label,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: excludeFromSemantics,
      child: child,
    );
  }
}

/// Semantic wrapper for headers/titles.
class SemanticHeader extends StatelessWidget {
  final Widget child;
  final String label;

  const SemanticHeader({
    super.key,
    required this.child,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      header: true,
      child: child,
    );
  }
}

/// Semantic wrapper for live regions (dynamic content updates).
class SemanticLiveRegion extends StatelessWidget {
  final Widget child;
  final String label;
  final bool isPolite;

  const SemanticLiveRegion({
    super.key,
    required this.child,
    required this.label,
    this.isPolite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: child,
    );
  }
}

/// Semantic wrapper for slider/progress elements.
class SemanticSlider extends StatelessWidget {
  final Widget child;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  const SemanticSlider({
    super.key,
    required this.child,
    required this.label,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = ((value - min) / (max - min) * 100).round();
    return Semantics(
      label: '$label: $percentage%',
      slider: true,
      value: '$percentage%',
      increasedValue: '${(percentage + 10).clamp(0, 100)}%',
      decreasedValue: '${(percentage - 10).clamp(0, 100)}%',
      onIncrease: onChanged != null
          ? () => onChanged!(((value + (max - min) / 10).clamp(min, max)))
          : null,
      onDecrease: onChanged != null
          ? () => onChanged!(((value - (max - min) / 10).clamp(min, max)))
          : null,
      child: child,
    );
  }
}

/// Utility to announce messages to screen readers.
class AccessibilityAnnouncer {
  /// Announce a message to screen readers (polite).
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Announce an urgent message to screen readers (assertive).
  static void announceUrgent(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr, assertiveness: Assertiveness.assertive);
  }
}

/// Extension for adding semantic properties to any widget.
extension SemanticExtensions on Widget {
  /// Add semantic label to this widget.
  Widget withSemanticLabel(String label) {
    return Semantics(
      label: label,
      child: this,
    );
  }

  /// Mark this widget as a button with a semantic label.
  Widget asSemanticButton(String label, {String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      child: this,
    );
  }

  /// Exclude this widget from semantics tree.
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }

  /// Mark this widget as a header.
  Widget asSemanticHeader(String label) {
    return Semantics(
      label: label,
      header: true,
      child: this,
    );
  }
}

/// Minimum touch target size for accessibility (48x48 dp per Material guidelines).
const double kMinInteractiveDimension = 48.0;

/// Ensure a widget meets minimum touch target size.
class MinTouchTarget extends StatelessWidget {
  final Widget child;
  final double minSize;

  const MinTouchTarget({
    super.key,
    required this.child,
    this.minSize = kMinInteractiveDimension,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }
}

/// Focus traversal order group for logical keyboard navigation.
class AccessibleFocusTraversal extends StatelessWidget {
  final Widget child;
  final FocusTraversalPolicy? policy;

  const AccessibleFocusTraversal({
    super.key,
    required this.child,
    this.policy,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: policy ?? WidgetOrderTraversalPolicy(),
      child: child,
    );
  }
}

/// Color contrast checker for accessibility compliance.
class AccessibilityColors {
  /// Check if text/foreground color has sufficient contrast against background.
  /// Returns true if contrast ratio meets WCAG AA standards (4.5:1 for normal text).
  static bool hasGoodContrast(Color foreground, Color background) {
    final ratio = _contrastRatio(foreground, background);
    return ratio >= 4.5;
  }

  /// Check if colors meet WCAG AAA standards (7:1 for normal text).
  static bool hasExcellentContrast(Color foreground, Color background) {
    final ratio = _contrastRatio(foreground, background);
    return ratio >= 7.0;
  }

  static double _contrastRatio(Color foreground, Color background) {
    final l1 = _relativeLuminance(foreground);
    final l2 = _relativeLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _relativeLuminance(Color color) {
    double r = _linearize(color.r / 255);
    double g = _linearize(color.g / 255);
    double b = _linearize(color.b / 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    // Approximate power function without dart:math
    final adjusted = (component + 0.055) / 1.055;
    return adjusted * adjusted * adjusted * adjusted.sqrt().sqrt();
  }
}

extension _Sqrt on double {
  double sqrt() {
    if (this <= 0) return 0;
    double x = this;
    double y = (x + 1) / 2;
    while (y < x) {
      x = y;
      y = (x + this / x) / 2;
    }
    return x;
  }
}
