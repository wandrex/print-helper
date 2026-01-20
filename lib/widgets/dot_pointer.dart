import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/colors.dart';

class DotPointer extends StatelessWidget {
  final int pageCount;
  final int selectedIndex;
  final Color primaryColor;
  final Color secondaryColor;
  const DotPointer({
    super.key,
    required this.pageCount,
    required this.selectedIndex,
    this.primaryColor = AppColors.tertiary,
    this.secondaryColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20.w,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: pageCount,
        itemBuilder: (_, index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOutCubicEmphasized,
            decoration: BoxDecoration(
              color:
                  selectedIndex == index
                      ? primaryColor
                      : secondaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            margin: EdgeInsets.all(3.w),
            width: selectedIndex == index ? 6.w : 5.w,
            height: selectedIndex == index ? 6.w : 5.w,
          );
        },
      ),
    );
  }
}
