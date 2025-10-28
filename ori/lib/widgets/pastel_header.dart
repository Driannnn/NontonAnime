import 'package:flutter/material.dart';

const pastelBlue = Color(0xFFA2D2FF);

class PastelHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const PastelHeaderBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;
    return Container(
      color: pastelBlue,
      padding: const EdgeInsets.only(
        top: 12 + 8, // kira2 status bar padding, boleh tweak
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          else
            // placeholder supaya title tetap center-ish
            const SizedBox(width: 40),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            Row(children: actions!)
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
