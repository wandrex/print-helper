import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:print_helper/admin/chat/chat_list.dart';
import 'package:print_helper/providers/auth_pro.dart';
import 'package:print_helper/widgets/loaders.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../constants/paths.dart';
import '../../../utils/textstyle_util.dart';
import '../../../widgets/image_widget.dart';
import '../../customers/customer_list.dart';
import '../../drawer/drawer.dart';

class ClientBottomBar extends StatefulWidget {
  final int pageNum;
  const ClientBottomBar({super.key, required this.pageNum});

  @override
  State<ClientBottomBar> createState() => _ClientBottomBarState();
}

class _ClientBottomBarState extends State<ClientBottomBar>
    with WidgetsBindingObserver {
  int pageNum = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    pageNum = widget.pageNum;
    WidgetsBinding.instance.addPostFrameCallback((_) async {});
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      _scaffoldKey.currentState?.openDrawer();
      return;
    }
    setState(() => pageNum = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(
        isFromAdmin: false,
        isFromClient: true,
        isFromStaff: false,
      ),
      extendBody: true,
      body: Consumer<AuthPro>(
        builder: (context, pro, _) {
          final user = pro.user;
          if (user == null || user.clientId == null) {
            return Center(child: showLoader());
          }
          return IndexedStack(
            index: pageNum,
            children: [
              CustomersScreen(
                isFromAdmin: false,
                isFromStaff: false,
                isFromClient: true,
                id: user.clientId!,
              ),
              const SizedBox(),
              ChatList(),
              const SizedBox(),
              const SizedBox(),
            ],
          );
        },
      ),

      bottomNavigationBar: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: decor(),
          child: BottomNavigationBar(
            onTap: _onItemTapped,
            elevation: 0,
            currentIndex: pageNum,
            items: tabItems,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.black,
            selectedItemColor: AppColors.white,
            unselectedItemColor: AppColors.white,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedLabelStyle: TextStyleData.selectedNavLbl,
            unselectedLabelStyle: TextStyleData.unSelectedNavLbl,
          ),
        ),
      ),
    );
  }

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
