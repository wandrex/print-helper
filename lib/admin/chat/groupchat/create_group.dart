import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:print_helper/providers/chat_pro.dart';
import 'package:print_helper/utils/console_util.dart';
import 'package:print_helper/widgets/custom_button.dart';
import 'package:provider/provider.dart';

import '../../../constants/colors.dart';
import '../../../constants/paths.dart';
import '../../../services/helpers.dart';
import '../../../widgets/image_widget.dart';
import '../../../widgets/loaders.dart';
import '../../../widgets/spacers.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/toasts.dart';

class CreateChatGroup extends StatefulWidget {
  final VoidCallback? onSuccess;
  const CreateChatGroup({super.key, this.onSuccess});

  @override
  State<CreateChatGroup> createState() => CreateChatGroupState();
}

class CreateChatGroupState extends State<CreateChatGroup> {
  final _formKey = GlobalKey<FormState>();
  final _searchCntrler = TextEditingController();
  final _groupNameCntrler = TextEditingController();
  bool _isExpanded = true;
  bool pickingFile = false;
  File? selectedImage;
  bool formSubmitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    _searchCntrler.dispose();
    _groupNameCntrler.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    if (pickingFile) return;
    pickingFile = true;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'],
      );
      if (result != null && result.files.single.path != null) {
        selectedImage = File(result.files.single.path!);
      }
    } catch (e) {
      printData(title: 'from pickImage', data: '$e', e: true);
    } finally {
      setState(() => pickingFile = false);
    }
  }

  Future<void> _onSave() async {
    final chatPro = getChatPro(context);
    if (_groupNameCntrler.text.trim().isEmpty) {
      showToast(message: "Group name is required");
      return;
    }
    if (chatPro.selectedUsers.length < 2) {
      showToast(message: "Select at least 2 members");
      return;
    }
    final userIds = chatPro.selectedUsers.map((e) => e.id).toList();
    FocusScope.of(context).unfocus();
    final success = await chatPro.createGroup(
      title: _groupNameCntrler.text.trim(),
      userIds: userIds,
      image: selectedImage,
      context: context,
    );
    if (!mounted) return;
    if (success) {
      showToast(message: "Group Created Successfully");
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.only(top: 40.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SafeArea(
            top: true,
            child: Column(
              children: [
                _header(context),
                Divider(thickness: 2.w, color: const Color(0x5F9E9E9E)),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Spacers.sb10(),
                          profileImage(),
                          Spacers.sb15(),
                          _formBody(),
                          Spacers.sb25(),
                          scrollUp(context),
                        ],
                      ),
                    ),
                  ),
                ),
                _cancelSaveBtn(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cancelSaveBtn(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Spacers.sbw15(),
              Expanded(
                child: CustomButton(
                  height: 40,
                  margin: EdgeInsets.symmetric(horizontal: 25),
                  textColor: AppColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  showBorder: true,
                  buttonColor: Colors.white,
                  stadium: false,
                  borderRadius: 18,
                  borderWidth: 1,
                  title: 'Cancel',
                  onTap: () {
                    context.read<ChatPro>().clearGroupCreationState();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Expanded(
                child: CustomButton(
                  height: 40,
                  margin: EdgeInsets.symmetric(horizontal: 25),
                  title: 'Create Group',
                  onTap: () => _onSave(),
                  buttonColor: AppColors.btnClr,
                  textColor: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  stadium: false,
                  borderRadius: 18,
                ),
              ),
              Spacers.sbw15(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formBody() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
      child: Column(
        children: [
          _buildLabel("Group Name"),
          Spacers.sb8(),
          TextField(
            decoration: _inputDecoration("Enter group name"),
            controller: _groupNameCntrler,
          ),
          Spacers.sb8(),
          _buildLabel("Add Members"),
          Spacers.sb8(),
          Consumer<ChatPro>(
            builder: (context, pro, child) {
              return Column(
                children: [
                  if (pro.selectedUsers.isNotEmpty) ...[
                    _buildSelectedUsersChips(pro),
                    Spacers.sb10(),
                  ],
                  TextField(
                    controller: _searchCntrler,
                    onChanged: pro.onSearchChanged,
                    decoration: _inputDecoration("Search users").copyWith(
                      suffixIcon: _searchCntrler.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchCntrler.clear();
                                pro.onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 10.h),
                    constraints: BoxConstraints(
                      minHeight: 120.h,
                      maxHeight: 300.h,
                    ),
                    width: double.infinity,
                    child: _buildSearchResultsList(pro),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedUsersChips(ChatPro pro) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWidget(
                text: "Selected Members (${pro.selectedUsers.length})",
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ),
            ],
          ),
          if (_isExpanded) ...[
            Spacers.sb10(),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: pro.selectedUsers.map((user) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.btnClr.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextWidget(
                        text: user.fullName,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      Spacers.sbw5(),
                      GestureDetector(
                        onTap: () => pro.removeSelectedUser(user),
                        child: ImageWidget(
                          image: Paths.delete,
                          width: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(ChatPro pro) {
    return pro.searchResults.isEmpty && _searchCntrler.text.isNotEmpty
        ? Center(
            heightFactor: 5,
            child: const TextWidget(
              text: "No results found",
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          )
        : pro.isLoading
        ? Center(child: showLoader())
        : ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: pro.searchResults.length,
            separatorBuilder: (c, i) => Spacers.sb5(),
            itemBuilder: (context, index) {
              final user = pro.searchResults[index];
              final isSelected = pro.selectedUsers.any((u) => u.id == user.id);
              return GestureDetector(
                onTap: () => pro.toggleUserSelection(user),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 15.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? Colors.grey : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50.r),
                        child: ImageWidget(
                          image: user.image != null && user.image!.isNotEmpty
                              ? user.image!
                              : Paths.user,
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Spacers.sbw12(),
                      Expanded(
                        child: TextWidget(
                          text: user.fullName,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade50,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget profileImage() {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: pickImage,
          child: Container(
            width: 140.w,
            height: 135.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
              image: selectedImage != null
                  ? DecorationImage(
                      image: FileImage(selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : DecorationImage(
                      image: AssetImage(Paths.user),
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => pickImage(),
            child: ImageWidget(image: Paths.edit, width: 20),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.w),
      child: Column(
        children: [
          Container(
            width: 45.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          Spacers.sb10(),
          Row(
            children: [
              ImageWidget(image: Paths.customers, fit: BoxFit.cover, width: 27),
              Spacers.sbw10(),
              Expanded(
                child: TextWidget(
                  text: "Create Group",
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.read<ChatPro>().clearGroupCreationState();
                  Navigator.of(context).pop();
                },
                child: Icon(
                  Icons.close,
                  size: 26.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextWidget(
        text: text,
        color: Colors.blueGrey.shade700,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }

  // Helper for Input Decoration
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 15.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.grey),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }
}
