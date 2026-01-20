import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:print_helper/widgets/image_widget.dart';
import '../chat/chat_list.dart';
import '../client/clients_list.dart';
import '../../constants/colors.dart';
import '../../constants/paths.dart';

class NavWidgets {
  static List<Widget> screens = [
    ClientScreen(isFromAdmin: true, isFromStaff: false, isFromClient: false),
    const SizedBox(),
    ChatList(),
    const SizedBox(),
    // ChatListScreenTest(),
    const SizedBox(),
  ];

  static List<BottomNavigationBarItem> tabItems = [
    _buildNavItem(Paths.clientprofile, Paths.clientprofile, ''),
    _buildNavItem(Paths.foldr, Paths.foldr, ''),
    _buildNavItem(Paths.chat, Paths.chat, ''),
    _buildNavItem(Paths.task, Paths.task, ''),
    _buildNavItem(Paths.menu, Paths.menu, ''),
  ];

  static BottomNavigationBarItem _buildNavItem(
    String icon,
    String activeIcon,
    String label,
  ) {
    return BottomNavigationBarItem(
      icon: ImageWidget(image: icon, width: 26, color: AppColors.white),
      activeIcon: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        padding: EdgeInsets.all(8.w),
        child: ImageWidget(image: icon, width: 26, color: AppColors.black),
      ),
      label: label,
    );
  }

  static BoxDecoration decor() {
    return BoxDecoration(
      color: AppColors.white,
      boxShadow: [
        BoxShadow(
          spreadRadius: 1.r,
          blurRadius: 8.r,
          color: AppColors.grey.withValues(alpha: 0.1),
        ),
      ],
    );
  }
}
