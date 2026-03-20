import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class CachedImage extends StatefulWidget {
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
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  String? _lastSuccessfulUrl;

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the image was successfully loaded previously and the URL changed,
    // we keep the previous URL to use as a placeholder.
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    // Attempt to upscale the image if it's a known thumbnail provider
    String finalUrl = widget.imageUrl!;
    if (widget.width != null && widget.width! > 200 || widget.height != null && widget.height! > 200) {
      finalUrl = _getHighResUrl(finalUrl);
    }

    Widget image = CachedNetworkImage(
      imageUrl: finalUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeOutDuration: Duration.zero,
      fadeInDuration: Duration.zero,
      placeholder: (context, url) {
        if (_lastSuccessfulUrl != null && _lastSuccessfulUrl != url) {
          // Show the last successful image as a placeholder while loading the new one
          return _buildImageWidget(_lastSuccessfulUrl!);
        }
        return widget.placeholder ?? _buildPlaceholder();
      },
      errorWidget: (context, url, error) => widget.errorWidget ?? _buildErrorWidget(),
      imageBuilder: (context, imageProvider) {
        // When the image successfully loads, we store the URL.
        // Note: Logic inside build is usually risky for side-effects, 
        // but since we're just updating a string for the NEXT build, it's okay here.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _lastSuccessfulUrl != finalUrl) {
            setState(() {
              _lastSuccessfulUrl = finalUrl;
            });
          }
        });
        
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: widget.fit,
            ),
          ),
        );
      },
    );

    if (widget.isCircle) {
      image = ClipOval(child: image);
    } else if (widget.borderRadius != null) {
      image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildImageWidget(String url) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(url),
          fit: widget.fit,
        ),
      ),
    );
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
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white10,
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isCircle
              ? null
              : (widget.borderRadius ?? BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white10,
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircle
            ? null
            : (widget.borderRadius ?? BorderRadius.circular(4)),
      ),
      child: const Center(child: Icon(Icons.music_note, color: Colors.white30)),
    );
  }
}
