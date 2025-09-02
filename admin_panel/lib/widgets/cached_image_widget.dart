// widgets/cached_image_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import '../utils/image_debug_helper.dart';

class CachedImageWidget extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  String? _currentImageUrl;
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(CachedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      setState(() {
        _currentImageUrl = widget.imageUrl;
        _retryCount = 0;
      });
    }
  }

  void _retryLoadImage() {
    if (_retryCount < _maxRetries) {
      setState(() {
        _retryCount++;
        // Force refresh by adding a timestamp parameter
        _currentImageUrl = widget.imageUrl != null 
            ? '${widget.imageUrl}?retry=${DateTime.now().millisecondsSinceEpoch}'
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentImageUrl == null || _currentImageUrl!.isEmpty) {
      return _buildDefaultIcon();
    }

    Widget imageWidget;

    // Use different image loading strategy for web vs mobile
    if (kIsWeb) {
      // For web, try CachedNetworkImage first, fallback to Image.network
      imageWidget = CachedNetworkImage(
        imageUrl: _currentImageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => widget.placeholder ?? _buildLoadingWidget(),
        errorWidget: (context, url, error) {
          ImageDebugHelper.logImageError(_currentImageUrl!, error);
          // For web CORS issues, try a different approach
          return _buildWebImageFallback();
        },
        httpHeaders: const {
          'Cache-Control': 'max-age=3600',
          'Accept': 'image/*',
          'Access-Control-Allow-Origin': '*',
        },
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    } else {
      // For mobile, use CachedNetworkImage
      imageWidget = CachedNetworkImage(
        imageUrl: _currentImageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => widget.placeholder ?? _buildLoadingWidget(),
        errorWidget: (context, url, error) {
          ImageDebugHelper.logImageError(_currentImageUrl!, error);
          return widget.errorWidget ?? _buildErrorWidget();
        },
        httpHeaders: const {
          'Cache-Control': 'max-age=3600',
          'Accept': 'image/*',
        },
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    }

    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[100],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.iron,
            color: Colors.grey[400],
            size: widget.height != null && widget.height! < 80 ? 20 : 30,
          ),
          if (widget.height == null || widget.height! >= 80) ...[
            const SizedBox(height: 4),
            if (_retryCount < _maxRetries)
              GestureDetector(
                onTap: _retryLoadImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              Text(
                'Image\nFailed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[100],
      child: Icon(
        Icons.iron,
        color: Colors.grey[400],
        size: widget.height != null && widget.height! < 80 ? 20 : 30,
      ),
    );
  }

  Widget _buildWebImageFallback() {
    // For web, try to create a proxy URL or use a different approach
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.iron,
            color: Colors.grey[400],
            size: widget.height != null && widget.height! < 80 ? 20 : 30,
          ),
          if (widget.height == null || widget.height! >= 80) ...[
            const SizedBox(height: 4),
            if (_retryCount < _maxRetries)
              GestureDetector(
                onTap: () {
                  // Try to reload with a proxy or different approach
                  _retryWithProxy();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              Text(
                'Image\nUnavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _retryWithProxy() {
    if (_retryCount < _maxRetries && widget.imageUrl != null) {
      setState(() {
        _retryCount++;
        // Try with a CORS proxy for web
        if (kIsWeb && widget.imageUrl!.contains('firebasestorage.googleapis.com')) {
          // Use Firebase Storage REST API with different approach
          _currentImageUrl = widget.imageUrl!;
          // Force widget rebuild
        } else {
          _currentImageUrl = '${widget.imageUrl}?retry=${DateTime.now().millisecondsSinceEpoch}';
        }
      });
    }
  }
}
