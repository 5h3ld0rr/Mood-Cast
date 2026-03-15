import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircle = false,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    // Attempt to upscale the image if it's a known thumbnail provider
    String finalUrl = imageUrl!;
    if (width != null && width! > 200 || height != null && height! > 200) {
      finalUrl = _getHighResUrl(finalUrl);
    }

    Widget image = CachedNetworkImage(
      imageUrl: finalUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );

    if (isCircle) {
      image = ClipOval(child: image);
    } else if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  String _getHighResUrl(String url) {
    if (url.contains('googleusercontent.com') || url.contains('ggpht.com')) {
      // YouTube Music thumbnails often have =w120-h120 or similar
      final regExp = RegExp(r'=w\d+-h\d+');
      if (regExp.hasMatch(url)) {
        return url.replaceFirst(regExp, '=w1024-h1024');
      }
      
      // Some URLs might have s120-c or similar
      final sRegExp = RegExp(r'/s\d+-c/');
      if (sRegExp.hasMatch(url)) {
        return url.replaceFirst(sRegExp, '/s1024-c/');
      }
    } else if (url.contains('i.ytimg.com')) {
      // Video thumbnails
      if (url.contains('default.jpg')) {
        return url.replaceFirst('default.jpg', 'maxresdefault.jpg');
      } else if (url.contains('hqdefault.jpg')) {
        return url.replaceFirst('hqdefault.jpg', 'maxresdefault.jpg');
      }
    }
    return url;
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white10,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle
              ? null
              : (borderRadius ?? BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white10,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle
            ? null
            : (borderRadius ?? BorderRadius.circular(4)),
      ),
      child: const Center(child: Icon(Icons.music_note, color: Colors.white30)),
    );
  }
}
