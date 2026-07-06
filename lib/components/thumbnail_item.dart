import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../graphql/fragments/attachment_fragment.graphql.dart';
import '../graphql/schema.graphql.dart';

class ThumbnailItem extends StatelessWidget {
  const ThumbnailItem({super.key, required this.attachment, this.size = 64});

  final Fragment$AttachmentFragment attachment;
  final double size;

  @override
  Widget build(BuildContext context) {
    late final IconData fileTypeIcon;

    switch (attachment.fileType) {
      case Enum$BlobFileType.APPLICATION_PDF:
        fileTypeIcon = Icons.description_rounded;
        break;
      case Enum$BlobFileType.IMAGE_GIF ||
          Enum$BlobFileType.IMAGE_JPEG ||
          Enum$BlobFileType.IMAGE_PNG ||
          Enum$BlobFileType.IMAGE_SVG_XML ||
          Enum$BlobFileType.IMAGE_WEBP:
        fileTypeIcon = Icons.photo_rounded;
        break;
      case Enum$BlobFileType.VIDEO_MP4 || Enum$BlobFileType.VIDEO_OGG || Enum$BlobFileType.VIDEO_WEBM:
        fileTypeIcon = Icons.movie_rounded;
        break;
      default:
        fileTypeIcon = Icons.insert_drive_file_rounded;
    }

    return (attachment.thumbnailUrl != null)
        ? Stack(
            children: [
              CachedNetworkImage(
                imageUrl: attachment.thumbnailUrl.toString(),
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Icon(
                  fileTypeIcon,
                  color: Colors.white,
                  size: 16.0,
                  shadows: [Shadow(color: Colors.black, offset: Offset(1.0, 1.0), blurRadius: 2.0)],
                ),
              ),
            ],
          )
        : Icon(fileTypeIcon, size: size);
  }
}
