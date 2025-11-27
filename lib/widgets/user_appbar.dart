import 'package:flutter/material.dart';

class UserAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String username;
  final String? avatarUrl;
  final VoidCallback onProfileTap;

  const UserAppBar({
    Key? key,
    required this.title,
    required this.username,
    required this.avatarUrl,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.blueAccent,
      actions: [
        IconButton(
          icon: CircleAvatar(
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl!)
                : const AssetImage('assets/default.jpg') as ImageProvider,
          ),
          onPressed: onProfileTap,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
