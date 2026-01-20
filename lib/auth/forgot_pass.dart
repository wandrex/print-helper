import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:print_helper/auth/login_screen.dart';
import 'package:print_helper/auth/reset_pass.dart';
import 'package:print_helper/services/helpers.dart';

import 'package:print_helper/constants/colors.dart';
import 'package:print_helper/constants/strings.dart';
import 'package:print_helper/widgets/custom_button.dart';
import 'package:print_helper/widgets/image_widget.dart';
import 'package:print_helper/widgets/spacers.dart';
import 'package:print_helper/widgets/text_widget.dart';
import 'package:print_helper/widgets/toasts.dart';

import '../constants/paths.dart';
import '../utils/regx.dart';
import '../widgets/field_widget.dart';

class ForgotPass extends StatefulWidget {
  const ForgotPass({super.key});
  @override
  State<ForgotPass> createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool loading = false;
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageWidget(image: Paths.bgg, fit: BoxFit.cover),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ImageWidget(image: Paths.logoWhite, width: 200),
                    Container(
                      margin: EdgeInsets.fromLTRB(12.w, 15.h, 12.w, 0),
                      padding: EdgeInsets.fromLTRB(35.w, 30.h, 35.w, 20.h),
                      decoration: BoxDecoration(
                        color: const Color(0XFFf1f1f2),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 10.w),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextWidget(
                                text: "Forgot\nPassword?",
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Spacers.sb10(),
                          Padding(
                            padding: EdgeInsets.only(left: 10.w),
                            child: TextWidget(
                              text:
                                  "No worries! It happens. Please enter your email and we will send you a OTP to reset your password.",
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                          Spacers.sb12(),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _title("Email Address"),
                                CustomTextField(
                                  hintText: "Enter your email",
                                  controller: _emailCtrl,
                                  regExpCondition: Regx.emailRegExp,
                                  errorText: AppStrings.emailError,
                                  regErrorText: AppStrings.emailRegError,
                                  bRadius: 15,
                                  fillColor: AppColors.white,
                                  filled: true,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18.w,
                                    vertical: 12.h,
                                  ),
                                ),
                                Spacers.sb15(),
                                _sendOtp(context),
                                Spacers.sb10(),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      navTo(
                                        context: context,
                                        page: const LoginScreen(),
                                        removeUntil: true,
                                      );
                                    },
                                    child: TextWidget(
                                      text: 'Back to Login',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sendOtp(dynamic context) {
    return CustomButton(
      title: "Send OTP",
      onTap: () async {
        FocusScope.of(context).unfocus();
        bool isValid = _formKey.currentState!.validate();
        if (isValid) {
          final authPro = getAuthPro(context);
          final success = await authPro.forgetPassword(
            email: _emailCtrl.text.trim(),
            context: context,
          );
          if (success) {
            navTo(
              context: context,
              page: ResetPass(email: _emailCtrl.text.trim()),
            );
          } else {
            showToast(message: 'OTP failed');
          }
        }
      },
      height: 40,
      fontSize: 14,
      borderRadius: 15,
      buttonColor: const Color(0xff00a650),
      stadium: false,
    );
  }

  Padding _title(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 18.w, bottom: 5.h),
      child: TextWidget(
        text: text,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }
}
