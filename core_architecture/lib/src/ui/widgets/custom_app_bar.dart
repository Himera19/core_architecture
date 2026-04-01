import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../tokens/app_colors.dart';
import '../../utils/extensions/context_extensions.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool canPop = context.canPop();

    return AppBar(
      title: title?.isEmpty ?? true ? null : Text(title!),
      centerTitle: centerTitle,
      actions: actions,
      leading: canPop
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimaryLight,
              ),
              onPressed: () => context.pop(),
            )
          : null,
      backgroundColor: context.colorScheme.surface,
      foregroundColor: context.colorScheme.onSurface,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
