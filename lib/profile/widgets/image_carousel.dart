import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    super.key,
    required this.images,
    this.showIndicators = true,
    this.borderRadius = 20,
    this.aspectRatio = 3 / 4,
  });

  final List<String> images;
  final bool showIndicators;
  final double borderRadius;
  final double aspectRatio;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageView = PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (value) => setState(() => _index = value),
          itemBuilder: (context, index) {
            return Image.network(
              widget.images[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            );
          },
        );

        final pageViewSized = constraints.maxHeight.isFinite
            ? pageView
            : AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: pageView,
              );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: pageViewSized,
            ),
            if (widget.showIndicators) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (dotIndex) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _index == dotIndex ? 20 : 8,
                    decoration: BoxDecoration(
                      color: _index == dotIndex
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
