import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../build_context.dart';
import '../graphql/fragments/user_fragment.graphql.dart';

class UserAvatarImage extends CircleAvatar {
  UserAvatarImage({super.key, required Fragment$UserFragment user, double size = 24})
    : super(
        radius: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size),
          child: CachedNetworkImage(
            useOldImageOnUrlChange: true,
            imageUrl: user.avatarImageUrl.toString(),
            placeholder: (context, url) => Center(
              child: Text(user.initials, style: TextStyle(fontSize: size)),
            ),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
}

class UserItem extends StatelessWidget {
  const UserItem({super.key, required this.user, this.onTap});

  final Fragment$UserFragment? user;
  final Function()? onTap;

  Row _getUserItem() {
    return Row(
      spacing: 6,
      children: [
        UserAvatarImage(size: 16, user: user!),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user!.displayName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('@${user!.username}', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Row(
        spacing: 6,
        children: [
          CircleAvatar(radius: 16, child: Icon(Icons.person_rounded)),
          Text(context.l10n.deletedUser, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      );
    }

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
        onTap: onTap,
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: _getUserItem()),
      );
    }

    return _getUserItem();
  }
}
