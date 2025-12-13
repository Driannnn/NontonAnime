import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../models/anime_models.dart';
import '../utils/image_proxy_utils.dart';
import 'common.dart';

class AnimeCarouselSlider extends StatefulWidget {
  final List<AnimeDisplay> items;
  const AnimeCarouselSlider({super.key, required this.items});

  @override
  State<AnimeCarouselSlider> createState() => _AnimeCarouselSliderState();
}

class _AnimeCarouselSliderState extends State<AnimeCarouselSlider>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.65);
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    if (widget.items.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _animationController.forward();
    _animationController.addListener(() {
      if (_animationController.isCompleted) {
        _nextPage();
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  void _nextPage() {
    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _previousPage() {
    if (_pageController.hasClients) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('Tidak ada anime')),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive height berdasarkan screen size
    final carouselHeight = screenWidth > 900
        ? screenHeight * 0.5 // Web: 50% dari screen height
        : (screenWidth > 600
            ? screenHeight * 0.35 // Tablet: 35% dari screen height
            : screenHeight * 0.28); // Mobile: 28% dari screen height

    final horizontalPadding = screenWidth > 900 ? screenWidth * 0.02 : screenWidth * 0.015;
    final spacingBetween = screenWidth > 900 ? screenHeight * 0.02 : screenHeight * 0.015;
    final indicatorHeight = 50.0;
    final spacingAfterCarousel = screenWidth > 900 ? screenHeight * 0.015 : screenHeight * 0.008;

    return Column(
      children: [
        // Carousel dengan ukuran responsive
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % widget.items.length;
              });
              _animationController.reset();
              if (widget.items.length > 1) {
                _animationController.forward();
              }
            },
            itemBuilder: (context, index) {
              final item = widget.items[index % widget.items.length];
              final isCurrent = _currentIndex == (index % widget.items.length);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: _CarouselCard(item: item, isCurrent: isCurrent),
              );
            },
          ),
        ),

        SizedBox(height: spacingBetween),

        // Indicators + Navigation Buttons
        SizedBox(
          height: indicatorHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Button
              if (widget.items.length > 1)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: screenWidth > 900 ? 18 : 16,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: _previousPage,
                    tooltip: 'Previous',
                  ),
                ),

              // Dots Indicator - Centered and Larger
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.items.length,
                        (index) => GestureDetector(
                          onTap: widget.items.length > 1
                              ? () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.fastOutSlowIn,
                                  );
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _currentIndex == index
                                ? (screenWidth > 900 ? 16 : 14)
                                : (screenWidth > 900 ? 12 : 10),
                            height: _currentIndex == index
                                ? (screenWidth > 900 ? 6 : 5)
                                : (screenWidth > 900 ? 4.5 : 3.5),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? cs.primary
                                  : cs.outline.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Next Button
              if (widget.items.length > 1)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: screenWidth > 900 ? 18 : 16,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: _nextPage,
                    tooltip: 'Next',
                  ),
                ),
            ],
          ),
        ),

        // Current Item Info
        SizedBox(height: spacingAfterCarousel),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.items[_currentIndex].title ?? 'No Title',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth > 900 ? 16 : 14,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenHeight * 0.003),
              Text(
                '${_currentIndex + 1} / ${widget.items.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: screenWidth > 900 ? 12 : 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final AnimeDisplay item;
  final bool isCurrent;

  const _CarouselCard({required this.item, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.slug != null && item.slug!.isNotEmpty) {
          context.go('/anime/${item.slug}');
        }
      },
      child: AnimatedScale(
        scale: isCurrent ? 1.0 : 0.88,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isCurrent ? 0.4 : 0.15),
                blurRadius: 10,
                offset: Offset(0, isCurrent ? 5 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: getProxyImageUrl(item.imageUrl!),
                      fit: BoxFit.cover,
                      placeholder: (c, _) => const ShimmerBox(),
                      errorWidget: (c, _, __) => const ImageFallback(),
                    )
                  : const ImageFallback(),
            ),
          ),
        ),
      ),
    );
  }
}
