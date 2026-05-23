import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Horizontal PageView yang menampung kartu-kartu statistik di dashboard.
/// Tinggi tetap supaya layout transaksi di bawahnya tidak loncat saat ganti
/// halaman.
class StatsCarousel extends StatefulWidget {
  final List<Widget> pages;
  final double height;

  const StatsCarousel({
    super.key,
    required this.pages,
    this.height = 180,
  });

  @override
  State<StatsCarousel> createState() => _StatsCarouselState();
}

class _StatsCarouselState extends State<StatsCarousel> {
  late final PageController _controller;
  int _currentIndex = 0;

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.pages.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: widget.pages[i],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            label:
                'Halaman ${_currentIndex + 1} dari ${widget.pages.length}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pages.length, (i) {
                final active = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
