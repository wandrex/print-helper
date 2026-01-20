import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/colors.dart';
import 'spacers.dart';

const _kBaseColor = Color(0xFFE8E8E8);
const _kHighlightColor = Color(0xFFF5F5F5);
const _kShimmerBase = Color(0xB3FFFFFF); // Colors.white70
const _kShimmerHighlight = Color(0x99FFFFFF); // Colors.white60
const _kDividerColor = Color(0x74B44753);
const _kGrey800 = Color(0xFF424242); // Colors.grey.shade800
const _kLineColor = AppColors.tertiary;

class CarousalShimmer extends StatelessWidget {
  const CarousalShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
      child: ColoredBox(
        color: AppColors.white,
        child: Column(
          children: [
            // CarouselSlider(
            //   options: CarouselOptions(
            //     height: 160.h,
            //     viewportFraction: .97,
            //     enableInfiniteScroll: true,
            //     autoPlay: false,
            //     enlargeCenterPage: true,
            //   ),
            //   items: List.generate(3, (index) => _shimmerItem()),
            // ),
            Spacers.sb10(),
          ],
        ),
      ),
    );
  }

  // Widget _shimmerItem() => const ShimmerBox(invert: true, radius: 25);
}

class BookNowShimmer extends StatelessWidget {
  const BookNowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerBox(width: 120, height: 30, radius: 30, center: true),
        Spacers.sb15(),
        const ShimmerBox(height: 50),
        Spacers.sb15(),
        Row(
          children: [
            Expanded(child: _shimmerDateBox()),
            _divider(),
            Expanded(child: _shimmerDateBox()),
          ],
        ),
        _line(),
        Row(
          children: [
            const ShimmerCircle(radius: 9, size: 18),
            Spacers.sbw20(),
            const ShimmerBox(width: 40, height: 20),
            Spacers.sbw10(),
            const Expanded(child: ShimmerBox(height: 50)),
            _divider(),
            const ShimmerCircle(radius: 9, size: 18),
            Spacers.sbw20(),
            const ShimmerBox(width: 40, height: 20),
            Spacers.sbw10(),
            const Expanded(child: ShimmerBox(height: 50)),
          ],
        ),
        _line(),
        Spacers.sb10(),
        const ShimmerBox(width: 100, height: 20),
        Spacers.sb15(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(9, (_) => const ShimmerCircle()),
        ),
      ],
    );
  }

  Widget _shimmerDateBox() {
    return Row(
      children: [
        const ShimmerCircle(radius: 9, size: 18),
        Spacers.sbw20(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 60, height: 15),
            Spacers.sb5(),
            const ShimmerBox(width: 90, height: 15),
            Spacers.sb5(),
            const ShimmerBox(width: 70, height: 12),
          ],
        ),
      ],
    );
  }

  Widget _divider() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 25.w),
    child: ColoredBox(
      color: _kDividerColor,
      child: SizedBox(width: 1.5.w, height: 60.h),
    ),
  );

  Widget _line() => Divider(color: _kLineColor, thickness: 1.2.w, height: 20.h);
}

class FeaturedRoomsShimmer extends StatelessWidget {
  const FeaturedRoomsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130.h,
      child: Card(
        elevation: 3.h,
        color: AppColors.white,
        margin: EdgeInsets.symmetric(horizontal: 14.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.r),
        ),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.r),
                  child: const ShimmerBox(
                    height: double.infinity,
                    radius: 15,
                    invert: true,
                  ),
                ),
              ),
              Spacers.sbw10(),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Spacers.sb10(),
                    const ShimmerBox(
                      width: 80,
                      height: 14,
                      radius: 6,
                      invert: true,
                    ),
                    Spacers.sb10(),
                    const ShimmerBox(
                      width: 120,
                      height: 12,
                      radius: 6,
                      invert: true,
                    ),
                    const Spacer(),
                    const ShimmerBox(
                      width: 70,
                      height: 20,
                      stadium: true,
                      invert: true,
                    ),
                    Spacers.sb10(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final bool center;
  final bool invert;
  final bool stadium;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.radius = 8,
    this.center = false,
    this.invert = false,
    this.stadium = false,
  });

  @override
  Widget build(BuildContext context) {
    final box = Shimmer.fromColors(
      baseColor: invert ? _kBaseColor : _kShimmerBase,
      highlightColor: invert ? _kHighlightColor : _kShimmerHighlight,
      child: Container(
        width: width.w,
        height: height.h,
        decoration: stadium
            ? const ShapeDecoration(color: _kGrey800, shape: StadiumBorder())
            : BoxDecoration(
                color: _kGrey800,
                borderRadius: BorderRadius.circular(radius.r),
              ),
      ),
    );
    return center ? Center(child: box) : box;
  }
}

class ShimmerCircle extends StatelessWidget {
  final double radius;
  final double size;

  const ShimmerCircle({super.key, this.radius = 16, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _kShimmerBase,
      highlightColor: _kShimmerHighlight,
      child: Container(
        width: size.sp,
        height: size.sp,
        decoration: BoxDecoration(
          color: _kGrey800,
          borderRadius: BorderRadius.circular(radius.r),
        ),
      ),
    );
  }
}
