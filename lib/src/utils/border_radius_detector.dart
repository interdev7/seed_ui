import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Traverses the widget tree upwards from the given [context] to automatically
/// detect the nearest [BorderRadius].
///
/// This is useful for overlay widgets (like `Spin` or `Tooltip`) that need
/// to match the rounded corners of their container seamlessly without
/// requiring explicit border radius parameters.
BorderRadiusGeometry? detectBorderRadiusFromContext(BuildContext context) {
  BorderRadiusGeometry? detectedRadius;

  context.visitAncestorElements((element) {
    final widget = element.widget;

    // Check specific widgets that commonly define border radius
    if (widget is ClipRRect) {
      detectedRadius = widget.borderRadius;
      return false; // stop traversal
    }

    if (widget is Container) {
      final decoration = widget.decoration;
      if (decoration is BoxDecoration && decoration.borderRadius != null) {
        detectedRadius = decoration.borderRadius;
        return false;
      }
    }

    if (widget is Card) {
      if (widget.shape is RoundedRectangleBorder) {
        detectedRadius = (widget.shape as RoundedRectangleBorder).borderRadius;
        return false;
      }
    }

    if (widget is Material) {
      if (widget.shape is RoundedRectangleBorder) {
        detectedRadius = (widget.shape as RoundedRectangleBorder).borderRadius;
        return false;
      }
    }

    // Inspect the underlying RenderObject
    if (element is RenderObjectElement) {
      final renderObject = element.renderObject;

      if (renderObject is RenderClipRRect) {
        detectedRadius = renderObject.borderRadius;
        return false;
      }

      if (renderObject is RenderDecoratedBox) {
        final decoration = renderObject.decoration;
        if (decoration is BoxDecoration && decoration.borderRadius != null) {
          detectedRadius = decoration.borderRadius;
          return false;
        }
      }
    }

    return true; // continue traversal
  });

  return detectedRadius;
}

/// Inspects the widget tree downwards from the given [widget] to automatically
/// detect the nearest [BorderRadius].
///
/// This is useful for wrapper widgets (like `Spin` or `Tooltip`) that need
/// to match the rounded corners of their child seamlessly without
/// requiring explicit border radius parameters.
BorderRadiusGeometry? detectBorderRadiusFromWidget(Widget? widget) {
  Widget? current = widget;

  while (current != null) {
    if (current is ClipRRect) {
      return current.borderRadius;
    }

    if (current is Container) {
      final decoration = current.decoration;
      if (decoration is BoxDecoration && decoration.borderRadius != null) {
        return decoration.borderRadius;
      }
    }

    if (current is Card) {
      if (current.shape is RoundedRectangleBorder) {
        return (current.shape as RoundedRectangleBorder).borderRadius;
      }
    }

    if (current is Material) {
      if (current.shape is RoundedRectangleBorder) {
        return (current.shape as RoundedRectangleBorder).borderRadius;
      }
    }

    // Attempt to traverse down to the child
    try {
      current = (current as dynamic).child as Widget?;
    } catch (_) {
      break;
    }
  }

  return null;
}
