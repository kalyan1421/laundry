import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomImageView extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CustomImageView({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.fadeOutDuration = const Duration(milliseconds: 200),
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Check if URL is empty or null
    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      memCacheHeight: height != null ? (height! * 2).toInt() : null, // 2x resolution for better quality
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 200),
      fadeOutDuration: fadeOutDuration ?? const Duration(milliseconds: 200),
      useOldImageOnUrlChange: true, // Show old image while loading new one
      filterQuality: FilterQuality.medium, // Better quality vs performance balance
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(context, url, error),
      cacheManager: DefaultCacheManager(),
      httpHeaders: const {
        'User-Agent': 'CloudIroningFactory/1.0',
        'Accept': 'image/*',
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget([BuildContext? context, String? url, dynamic error]) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Image not available',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced cache manager for better performance
class DefaultCacheManager extends CacheManager {
  static const key = 'customCacheKey';

  DefaultCacheManager() : super(Config(
    key,
    stalePeriod: const Duration(days: 7), // Keep images for 7 days
    maxNrOfCacheObjects: 1000, // Increased cache size
    repo: JsonCacheInfoRepository(databaseName: key),
    fileService: HttpFileService(),
  ));
} 