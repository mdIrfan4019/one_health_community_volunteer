import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cohv/core/services/local_media_cache_service.dart';
import 'package:cohv/core/theme/app_colors.dart';

class FallbackNetworkImage extends StatefulWidget {
  final List<String> urls;
  final String? localFilePath;
  final String? fileName;
  final Map<String, String>? headers;
  final Widget Function(BuildContext context) fallbackBuilder;
  final BoxFit fit;
  final double? width;
  final double? height;

  const FallbackNetworkImage({
    super.key,
    required this.urls,
    this.localFilePath,
    this.fileName,
    this.headers,
    required this.fallbackBuilder,
    this.fit = BoxFit.cover,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  State<FallbackNetworkImage> createState() => _FallbackNetworkImageState();
}

class _FallbackNetworkImageState extends State<FallbackNetworkImage> {
  int _currentIndex = 0;
  File? _resolvedLocalFile;

  @override
  void initState() {
    super.initState();
    _resolveLocalFile();
  }

  @override
  void didUpdateWidget(covariant FallbackNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls.join(',') != widget.urls.join(',') ||
        oldWidget.localFilePath != widget.localFilePath ||
        oldWidget.fileName != widget.fileName) {
      _currentIndex = 0;
      _resolveLocalFile();
    }
  }

  void _resolveLocalFile() {
    // 1. Direct synchronous check
    if (widget.localFilePath != null &&
        widget.localFilePath!.isNotEmpty &&
        !widget.localFilePath!.startsWith('http') &&
        File(widget.localFilePath!).existsSync()) {
      _resolvedLocalFile = File(widget.localFilePath!);
      return;
    }

    // 2. Asynchronous deep resolution via LocalMediaCacheService
    LocalMediaCacheService.instance
        .findLocalFile(
          storagePath: widget.localFilePath,
          fileName: widget.fileName,
        )
        .then((file) {
      if (file != null && mounted) {
        setState(() => _resolvedLocalFile = file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. If local device file exists, display immediately
    if (_resolvedLocalFile != null && _resolvedLocalFile!.existsSync()) {
      return Image.file(
        _resolvedLocalFile!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => widget.fallbackBuilder(context),
      );
    }

    // Synchronous fallback check for localFilePath
    if (widget.localFilePath != null &&
        widget.localFilePath!.isNotEmpty &&
        !widget.localFilePath!.startsWith('http') &&
        File(widget.localFilePath!).existsSync()) {
      return Image.file(
        File(widget.localFilePath!),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => widget.fallbackBuilder(context),
      );
    }

    // 2. If no candidate URLs or all candidate URLs failed, show fallback
    if (widget.urls.isEmpty || _currentIndex >= widget.urls.length) {
      return widget.fallbackBuilder(context);
    }

    final currentUrl = widget.urls[_currentIndex];

    return Image.network(
      currentUrl,
      key: ValueKey(currentUrl),
      headers: widget.headers,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          // Successfully loaded from network: auto-cache for future offline sessions
          final name = widget.fileName ??
              widget.localFilePath?.split('/').last ??
              currentUrl.split('/').last.split('?').first;
          if (name.isNotEmpty && !name.contains('?')) {
            LocalMediaCacheService.instance.cacheRemoteMedia(currentUrl, name);
          }
          return child;
        }
        return Container(
          color: const Color(0xFFFDF2F8),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[AVATAR] Candidate URL failed ($_currentIndex/${widget.urls.length}): $currentUrl');
        if (_currentIndex + 1 < widget.urls.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _currentIndex++);
            }
          });
          return Container(
            color: const Color(0xFFFDF2F8),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        }
        return widget.fallbackBuilder(context);
      },
    );
  }
}
