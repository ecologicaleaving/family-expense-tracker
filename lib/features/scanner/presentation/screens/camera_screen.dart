import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/services/camera_service.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/scanner_provider.dart';

/// Camera screen for capturing receipt photos.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitializing = true;
  FlashMode _flashMode = FlashMode.auto;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      await CameraService.initialize();

      if (!CameraService.hasCameras) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Nessuna fotocamera disponibile';
        });
        return;
      }

      _controller = await CameraService.createController(
        resolution: ResolutionPreset.high,
      );

      if (_controller == null) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Impossibile inizializzare la fotocamera';
        });
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Errore fotocamera: $e';
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final imageData = await CameraService.takePicture();
      if (imageData != null) {
        ref.read(scannerProvider.notifier).setCapturedImage(imageData);
        if (mounted) {
          context.go('/review-scan');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante lo scatto: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final imageData = await CameraService.pickFromGallery();
    if (imageData != null) {
      ref.read(scannerProvider.notifier).setCapturedImage(imageData);
      if (mounted) {
        context.go('/review-scan');
      }
    }
  }

  Future<void> _toggleFlash() async {
    final newMode = await CameraService.toggleFlash();
    if (newMode != null) {
      setState(() {
        _flashMode = newMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Scansiona scontrino'),
        actions: [
          if (_controller != null && _controller!.value.isInitialized)
            IconButton(
              icon: Icon(_getFlashIcon()),
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: _buildBody(theme),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isInitializing) {
      return const Center(
        child: LoadingIndicator(
          message: 'Inizializzazione fotocamera...',
          color: Colors.white,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: Colors.white54,
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SecondaryButton(
                onPressed: _pickFromGallery,
                label: 'Scegli dalla galleria',
                icon: Icons.photo_library,
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: LoadingIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Center(
          child: CameraPreview(_controller!),
        ),
        // Overlay frame guide
        Positioned.fill(
          child: CustomPaint(
            painter: _ReceiptFramePainter(),
          ),
        ),
        // Instructions
        Positioned(
          left: 24,
          right: 24,
          bottom: 120,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Inquadra lo scontrino all\'interno della cornice',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery button
            IconButton(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library, size: 32),
              color: Colors.white,
            ),
            // Capture button
            GestureDetector(
              onTap: _controller != null && _controller!.value.isInitialized
                  ? _takePicture
                  : null,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Manual entry button
            IconButton(
              onPressed: () => context.go('/add-expense'),
              icon: const Icon(Icons.edit, size: 32),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }
}

/// Custom painter for receipt frame overlay.
class _ReceiptFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Calculate frame dimensions
    final frameWidth = size.width * 0.85;
    final frameHeight = size.height * 0.6;
    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;

    // Draw corners
    const cornerLength = 40.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Top left corner
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(left + frameWidth - cornerLength, top),
      Offset(left + frameWidth, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top),
      Offset(left + frameWidth, top + cornerLength),
      cornerPaint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(left, top + frameHeight - cornerLength),
      Offset(left, top + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + frameHeight),
      Offset(left + cornerLength, top + frameHeight),
      cornerPaint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(left + frameWidth - cornerLength, top + frameHeight),
      Offset(left + frameWidth, top + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top + frameHeight - cornerLength),
      Offset(left + frameWidth, top + frameHeight),
      cornerPaint,
    );

    // Semi-transparent overlay outside frame
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);

    // Top overlay
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, top),
      overlayPaint,
    );
    // Bottom overlay
    canvas.drawRect(
      Rect.fromLTRB(0, top + frameHeight, size.width, size.height),
      overlayPaint,
    );
    // Left overlay
    canvas.drawRect(
      Rect.fromLTRB(0, top, left, top + frameHeight),
      overlayPaint,
    );
    // Right overlay
    canvas.drawRect(
      Rect.fromLTRB(left + frameWidth, top, size.width, top + frameHeight),
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
