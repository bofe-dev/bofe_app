import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../build_context.dart';
import '../../graphql/queries/card_attachment.graphql.dart';
import '../../graphql/schema.graphql.dart';
import '../query_result_builder.dart';

void showCardAttachmentDialog(BuildContext context, {required String cardId, required String id}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog.fullscreen(
      child: _CardAttachmentDialog(cardId: cardId, id: id),
    ),
  );
}

class _CardAttachmentDialog extends StatelessWidget {
  const _CardAttachmentDialog({required this.cardId, required this.id});

  final String cardId;
  final String id;

  Future<void> _download(BuildContext context) async {
    final result = await context.graphQLClient.query$CardAttachment(
      Options$Query$CardAttachment(
        variables: Variables$Query$CardAttachment(cardId: cardId, id: id),
      ),
    );
    final attachmentUrl = result.parsedData?.card?.attachment?.url.replace(queryParameters: {'download': 'true'});

    if (attachmentUrl != null && await canLaunchUrl(attachmentUrl)) {
      await launchUrl(attachmentUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Query$CardAttachment$Widget(
      options: Options$Query$CardAttachment(
        fetchPolicy: FetchPolicy.cacheFirst,
        variables: Variables$Query$CardAttachment(cardId: cardId, id: id),
      ),
      builder: (result, {fetchMore, refetch}) => QueryResultBuilder(
        result: result,
        refetch: refetch,
        buildIf: (parsedData) => parsedData?.card?.attachment != null,
        builder: (parsedData) {
          late final Widget attachmentWidget;

          switch (parsedData.card!.attachment!.fileType) {
            case Enum$BlobFileType.APPLICATION_PDF:
              attachmentWidget = PdfViewer.uri(parsedData.card!.attachment!.url);
              break;
            case Enum$BlobFileType.IMAGE_GIF ||
                Enum$BlobFileType.IMAGE_JPEG ||
                Enum$BlobFileType.IMAGE_PNG ||
                Enum$BlobFileType.IMAGE_WEBP:
              attachmentWidget = _ImageViewer(url: parsedData.card!.attachment!.url, onError: () => refetch?.call());
              break;
            case Enum$BlobFileType.IMAGE_SVG_XML:
              attachmentWidget = SvgPicture.network(
                parsedData.card!.attachment!.url.toString(),
                width: double.infinity,
                height: double.infinity,
                placeholderBuilder: (context) => CircularProgressIndicator(),
              );
              break;
            case Enum$BlobFileType.VIDEO_MP4 || Enum$BlobFileType.VIDEO_OGG || Enum$BlobFileType.VIDEO_WEBM:
              attachmentWidget = _VideoPlayer(url: parsedData.card!.attachment!.url);
              break;
            default:
              attachmentWidget = Text(context.l10n.thisFileCantBeDisplayed);
              break;
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(parsedData.card!.attachment!.fileName),
              actions: [
                IconButton(
                  icon: Icon(Icons.download_rounded),
                  tooltip: context.l10n.download,
                  onPressed: () => _download(context),
                ),
              ],
            ),
            body: Center(child: attachmentWidget),
          );
        },
      ),
    );
  }
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.url, required this.onError});

  final Uri url;
  final Function() onError;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  int _loadAttempts = 0;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      useOldImageOnUrlChange: true,
      errorListener: (error) {
        if (_loadAttempts++ < 3) {
          widget.onError();
        }
      },
      progressIndicatorBuilder: (context, url, progress) => CircularProgressIndicator(value: progress.progress),
      imageUrl: widget.url.toString(),
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  const _VideoPlayer({required this.url});

  final Uri url;

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late final VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _videoPlayerController = VideoPlayerController.networkUrl(widget.url, viewType: VideoViewType.platformView);

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(videoPlayerController: _videoPlayerController, autoPlay: true);

      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController != null && _videoPlayerController.value.isInitialized
        ? Chewie(controller: _chewieController!)
        : const CircularProgressIndicator();
  }
}
