import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../graphql/fragments/attachment_thumbnail_small_fragment.graphql.dart';
import '../graphql/fragments/attachment_thumbnail_medium_fragment.graphql.dart';
import '../graphql/fragments/attachment_thumbnail_large_fragment.graphql.dart';

class CachedImageAttachment extends CachedNetworkImage {
  CachedImageAttachment.thumbnailSmall({
    super.key,
    required Fragment$AttachmentThumbnailSmallFragment attachment,
    super.fit = BoxFit.cover,
    super.width,
    super.height,
  }) : assert(attachment.thumbnailUrl != null),
       super(imageUrl: attachment.thumbnailUrl!.toString(), useOldImageOnUrlChange: true);

  CachedImageAttachment.thumbnailMedium({
    super.key,
    required Fragment$AttachmentThumbnailMediumFragment attachment,
    super.fit = BoxFit.cover,
    super.width,
    super.height,
  }) : assert(attachment.thumbnailUrl != null),
       super(imageUrl: attachment.thumbnailUrl!.toString(), useOldImageOnUrlChange: true);

  CachedImageAttachment.thumbnailLarge({
    super.key,
    required Fragment$AttachmentThumbnailLargeFragment attachment,
    super.fit = BoxFit.cover,
    super.width,
    super.height,
  }) : assert(attachment.thumbnailUrl != null),
       super(imageUrl: attachment.thumbnailUrl!.toString(), useOldImageOnUrlChange: true);
}
