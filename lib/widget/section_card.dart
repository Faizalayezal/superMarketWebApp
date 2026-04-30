import 'package:flutter/material.dart';
import 'package:shivam_super_market/core/config.dart';

/// Styled card container with optional title and action button
/// Used in Settings (Units section, Categories section, Config section)
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const SectionCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: myDecoration,
      child: child,
    );
  }
}

/// Header row with title + an action button (e.g., "+ Add Unit")
class SectionHeader extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onButtonPressed;

  const SectionHeader({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: onButtonPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
          ),
          child: Text(
            buttonLabel,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
