import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import 'error_display.dart';
import 'loading_indicator.dart';

/// Full-screen receipt image viewer with zoom and pan support.
///
/// Uses [PhotoView] for pinch-to-zoom and pan gestures.
/// Displays loading indicator while image loads and error state
/// if the image fails to load.
///
/// Example usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => ReceiptImageViewer(imageUrl: signedUrl),
///   ),
/// );
/// ```
class ReceiptImageViewer extends StatefulWidget {
  const ReceiptImageViewer({
    super.key,
    required this.imageUrl,
  });

  /// The URL of the receipt image to display.
  /// Should be a signed URL with read access.
  final String imageUrl;

  @override
  State<ReceiptImageViewer> createState() => _ReceiptImageViewerState();
}

class _ReceiptImageViewerState extends State<ReceiptImageViewer> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  void _onImageLoadStart() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  void _onImageLoadComplete() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onImageLoadError(Object error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Impossibile caricare l\'immagine della ricevuta';
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _close,
        ),
        title: const Text('Ricevuta'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: ErrorDisplay(
          message: _errorMessage ?? 'Errore durante il caricamento',
          icon: Icons.image_not_supported_outlined,
          title: 'Immagine non disponibile',
          onRetry: _retry,
        ),
      );
    }

    return Stack(
      children: [
        PhotoView(
          imageProvider: NetworkImage(widget.imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) {
            // Don't show the built-in loading if we're handling it ourselves
            return const SizedBox.shrink();
          },
          onTapDown: (context, details, value) {
            // Double tap handled by PhotoView internally
          },
        ),
        // Image loading listener via precacheImage
        _ImageLoadingListener(
          imageUrl: widget.imageUrl,
          onLoadStart: _onImageLoadStart,
          onLoadComplete: _onImageLoadComplete,
          onLoadError: _onImageLoadError,
        ),
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black,
            child: const Center(
              child: LoadingIndicator(
                message: 'Caricamento ricevuta...',
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

/// Internal widget to listen for image loading events.
class _ImageLoadingListener extends StatefulWidget {
  const _ImageLoadingListener({
    required this.imageUrl,
    required this.onLoadStart,
    required this.onLoadComplete,
    required this.onLoadError,
  });

  final String imageUrl;
  final VoidCallback onLoadStart;
  final VoidCallback onLoadComplete;
  final void Function(Object error) onLoadError;

  @override
  State<_ImageLoadingListener> createState() => _ImageLoadingListenerState();
}

class _ImageLoadingListenerState extends State<_ImageLoadingListener> {
  late ImageStream _imageStream;
  late ImageStreamListener _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_ImageLoadingListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageStream.removeListener(_imageStreamListener);
      _loadImage();
    }
  }

  void _loadImage() {
    widget.onLoadStart();

    final imageProvider = NetworkImage(widget.imageUrl);
    _imageStream = imageProvider.resolve(const ImageConfiguration());

    _imageStreamListener = ImageStreamListener(
      (info, synchronousCall) {
        widget.onLoadComplete();
      },
      onError: (exception, stackTrace) {
        widget.onLoadError(exception);
      },
    );

    _imageStream.addListener(_imageStreamListener);
  }

  @override
  void dispose() {
    _imageStream.removeListener(_imageStreamListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything visible
    return const SizedBox.shrink();
  }
}

/// Static helper to open the receipt image viewer.
///
/// Example:
/// ```dart
/// ReceiptImageViewer.show(context, signedUrl);
/// ```
extension ReceiptImageViewerNavigation on ReceiptImageViewer {
  /// Opens the receipt image viewer as a full-screen route.
  static Future<void> show(BuildContext context, String imageUrl) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptImageViewer(imageUrl: imageUrl),
        fullscreenDialog: true,
      ),
    );
  }
}
