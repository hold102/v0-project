/*
 * member_avatar.dart — A simple circular-ish container displaying an emoji avatar
 * Size, background color, and border are configurable.
 */
import 'package:flutter/material.dart';

class MemberAvatar extends StatelessWidget {
  final String emoji;
  final double size;
  final Color? backgroundColor;
  final bool showBorder;

  const MemberAvatar({
    super.key,
    required this.emoji,
    this.size = 40,
    this.backgroundColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(size / 3),
        border: showBorder
            ? Border.all(color: Colors.grey.shade200, width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.45),
      ),
    );
  }
}
