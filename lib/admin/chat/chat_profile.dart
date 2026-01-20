import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:print_helper/constants/colors.dart';
import 'package:print_helper/models/profile_models.dart';
import 'package:print_helper/providers/chat_pro.dart';
import 'package:print_helper/services/helpers.dart';
import 'package:print_helper/widgets/image_widget.dart';
import 'package:print_helper/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../../constants/paths.dart' show Paths;
import '../../widgets/spacers.dart';

class ProfileDetails extends StatefulWidget {
  final String id;
  const ProfileDetails({super.key, required this.id});
  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pro = getChatPro(context);
      pro.fetchUserProfile(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.back, color: Colors.black, size: 30.sp),
        ),
      ),
      body: Consumer<ChatPro>(
        builder: (context, provider, child) {
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!),
                  ElevatedButton(
                    onPressed: () => provider.fetchUserProfile(widget.id),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }
          final data = provider.userProfile;
          if (data == null) return const SizedBox.shrink();
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Column(
              children: [
                _profileHeader(data),
                Spacers.sb15(),
                data.role == 1 || data.role == 2
                    ? SizedBox()
                    : ExpandableCard(
                        title: "Company",
                        child: _companyBody(data),
                      ),
                Spacers.sb15(),
                ExpandableCard(title: "About", child: _aboutSection(data)),
                Spacers.sb15(),
                ExpandableCard(
                  title: "Recordings",
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: TextWidget(
                      text: "No Recordings",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                    //  _recordings(),
                  ),
                ),
                Spacers.sb15(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileHeader(ProfileData data) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(70.r),
            border: Border.all(color: const Color(0x779E9E9E)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(70.r),
            child: ImageWidget(
              image: data.image.isNotEmpty ? data.image : Paths.user,
              height: 140,
              width: 140,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Spacers.sb8(),
        TextWidget(text: data.name, fontSize: 18, fontWeight: FontWeight.w600),
        data.role == 1 || data.role == 2
            ? SizedBox()
            : TextWidget(
                text: "Wholesale",
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
      ],
    );
  }

  Widget _companyBody(ProfileData data) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.r),
              border: Border.all(color: const Color(0x779E9E9E)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(50.r),
              child: ImageWidget(
                image: data.companyLogo.isEmpty ? Paths.user : data.companyLogo,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Spacers.sbw15(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: data.companyName,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                Spacers.sb5(),
                TextWidget(
                  text:
                      "${data.companySegment} | ${DateFormat('MM/dd/yy - hh:mma').format(data.createdAt).toLowerCase()}",
                  fontSize: 11.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
                Spacers.sb5(),
                TextWidget(
                  text:
                      "${data.projectsCount} Projects - ${data.filesCount} Files",
                  fontSize: 11.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
                Spacers.sb5(),
                TextWidget(
                  text: "${data.contactsCount} Contact(s)",
                  fontSize: 11.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
                Spacers.sb12(),
                SizedBox(
                  height: 30.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () {},
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: TextWidget(
                        text: "View Page",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutSection(ProfileData data) {
    return Align(
      alignment: AlignmentGeometry.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.phones.isNotEmpty) ...[
              TextWidget(
                text: "Phones:",
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              Spacers.sb2(),
              ...data.phones.map(
                (phone) => Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: TextWidget(
                    text: phone,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
            Spacers.sb5(),
            if (data.emails.isNotEmpty) ...[
              TextWidget(
                text: "Email:",
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              Spacers.sb2(),
              ...data.emails.map(
                (email) => Padding(
                  padding: EdgeInsets.only(bottom: 2.0.h),
                  child: TextWidget(
                    text: email,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
            Spacers.sb10(),
            if (data.preferredLanguages.isNotEmpty) ...[
              TextWidget(
                text: "Preferred Languages:",
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              Spacers.sb2(),
              ...data.preferredLanguages.map(
                (lang) => Padding(
                  padding: EdgeInsets.only(bottom: 2.0.h),
                  child: TextWidget(
                    text: lang,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Spacers.sb5(),
            ],
            Spacers.sb10(),
            if (data.skills.isNotEmpty) ...[
              TextWidget(
                text: "Skills:",
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              Spacers.sb2(),
              ...data.skills.map(
                (skill) => Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: TextWidget(
                    text: skill,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Spacers.sb5(),
            ],
            Spacers.sb5(),
          ],
        ),
      ),
    );
  }

  Widget recordings() {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: EdgeInsets.only(bottom: 10.h, left: 18.w, right: 18.w),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xffF2F2F2),
            borderRadius: BorderRadius.circular(13.r),
          ),
          child: Row(
            children: [
              Container(
                height: 36.h,
                width: 36.w,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: const Icon(Icons.play_arrow),
              ),
              Spacers.sbw12(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "•၊၊||၊|။||||။၊|၊||၊||၊။၊|။•",
                      fontSize: 17,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    Spacers.sb5(),
                    TextWidget(
                      text: "00:00/00:30",
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextWidget(
                        text: "2024/02/05 - 4:56 pm",
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.file_download_outlined, size: 28.sp),
            ],
          ),
        );
      }),
    );
  }
}

class ExpandableCard extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const ExpandableCard({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF3F3F3),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14.r),
                      bottom: _expanded ? Radius.zero : Radius.circular(14.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextWidget(
                        text: widget.title,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: _expanded ? .5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const ImageWidget(image: Paths.up, height: 10),
                      ),
                    ],
                  ),
                ),
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _expanded ? widget.child : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
