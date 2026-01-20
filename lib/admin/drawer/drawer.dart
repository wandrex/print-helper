import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:print_helper/admin/accounts/accounts_list.dart';
import 'package:print_helper/providers/auth_pro.dart';
import 'package:print_helper/services/helpers.dart';
import 'package:print_helper/admin/settings/settings.dart';
import 'package:print_helper/widgets/image_widget.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/paths.dart';
import '../../utils/formatter.dart';
import '../../widgets/spacers.dart';
import '../../widgets/text_widget.dart';

class CustomDrawer extends StatefulWidget {
  final bool isFromAdmin;
  final bool isFromClient;
  final bool isFromStaff;
  const CustomDrawer({
    super.key,
    required this.isFromAdmin,
    required this.isFromClient,
    required this.isFromStaff,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool billingExpanded = true;
  @override
  Widget build(BuildContext context) {
    final provider = getCustPro(context);
    return Container(
      decoration: BoxDecoration(
        color:
            widget.isFromClient && provider.client?.brandingPrimaryColor != null
            ? hexToColor(provider.client!.brandingPrimaryColor)
            : AppColors.white,
        borderRadius: BorderRadius.only(topRight: Radius.circular(25.r)),
      ),
      width: 280.w,
      child: Consumer<AuthPro>(
        builder: (context, pro, _) {
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 18.h, 10.w, 10.h),
                  child: Row(
                    children: [
                      TextWidget(
                        text: "Menu",
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          size: 26.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(),
                Padding(
                  padding: EdgeInsets.only(left: 15.w, top: 5.h, bottom: 12.h),
                  child: Row(
                    children: [
                      Container(
                        width: 38.w,
                        height: 38.h,
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40.r),
                          border: Border.all(color: AppColors.grey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40.r),
                          child: ImageWidget(
                            image:
                                (pro.user?.image == null ||
                                    pro.user!.image!.isEmpty)
                                ? Paths.user
                                : pro.user!.image!,
                            width: 36,
                            height: 35,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Spacers.sbw12(),
                      TextWidget(
                        text: pro.user?.name ?? "",
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ],
                  ),
                ),
                _menuItem(
                  icon: Paths.timeIcon,
                  title: "Time Track",
                  onTap: () {},
                ),
                widget.isFromAdmin
                    // || widget.isFromStaff
                    ? _menuItem(
                        icon: Paths.accounts,
                        title: "Accounts",
                        onTap: () {
                          navTo(
                            context: context,
                            page: AccountsScreen(
                              isFromAdmin: widget.isFromAdmin,
                            ),
                          );
                        },
                      )
                    : SizedBox(),
                widget.isFromAdmin
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(18.w, 14.h, 10.w, 0),
                        child: GestureDetector(
                          onTap: () => setState(
                            () => billingExpanded = !billingExpanded,
                          ),
                          child: Row(
                            children: [
                              ImageWidget(
                                image: Paths.billingIcon,
                                width: 25.w,
                              ),
                              Spacers.sbw20(),
                              Expanded(
                                child: TextWidget(
                                  text: "Billing",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                billingExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 24.sp,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(),
                if (widget.isFromAdmin)
                  if (billingExpanded) ...[
                    Spacers.sb10(),
                    _subMenuItem(
                      title: "Invoices",
                      icon: Paths.invoices,
                      onTap: () {},
                    ),
                    Spacers.sb10(),
                    _subMenuItem(
                      title: "Subscriptions",
                      icon: Paths.subscriptions,
                      onTap: () {},
                    ),
                    Spacers.sb10(),
                    _subMenuItem(
                      title: "Orders",
                      icon: Paths.orders,
                      onTap: () {},
                    ),
                  ],
                Spacers.sb15(),
                widget.isFromAdmin
                    ? _menuItem(
                        icon: Paths.settings,
                        title: "Settings",
                        onTap: () {
                          navTo(context: context, page: SettingsScreen());
                        },
                      )
                    : SizedBox(),
                if (widget.isFromAdmin) Spacers.sb15(),
                Padding(
                  padding: EdgeInsets.only(left: 18.w),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        size: 25.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      Spacers.sbw20(),
                      TextWidget(
                        text: "About Us",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
                Spacer(),
                _menuItem(
                  icon: Paths.login,
                  title: "Logout",
                  onTap: () {
                    final pro = Provider.of<AuthPro>(context, listen: false);
                    pro.logout(context);
                  },
                ),
                Spacers.sb25(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _menuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 10.w, 8.h),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            ImageWidget(image: icon, width: 25.w),
            Spacers.sbw20(),
            TextWidget(text: title, fontSize: 14, fontWeight: FontWeight.w500),
          ],
        ),
      ),
    );
  }

  Widget _subMenuItem({
    required String title,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: 55.w, top: 12.h),
        child: Row(
          children: [
            ImageWidget(image: icon, width: 25, color: Colors.black),
            Spacers.sbw20(),
            TextWidget(text: title, fontSize: 14, fontWeight: FontWeight.w400),
          ],
        ),
      ),
    );
  }
}
