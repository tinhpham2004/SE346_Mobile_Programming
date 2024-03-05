import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextStyle extends TextStyle {
  static TextStyle h1(Color color) {
    return TextStyle(
      fontSize: 80.sp,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle h2(Color color) {
    return TextStyle(
      fontSize: 50.sp,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle h3(Color color) {
    return TextStyle(
      fontSize: 30.sp,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle profileHeader(Color color) {
    return TextStyle(
      fontSize: 50.sp,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle cardTextStyle(Color color) {
    return TextStyle(
      fontSize: 35.sp,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle error_text_style() {
    return TextStyle(
      fontSize: 30.sp,
      fontWeight: FontWeight.w400,
      color: Colors.red,
    );
  }

  static TextStyle messageStyle(Color color) {
    return TextStyle(
      fontSize: 35.sp,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle communityRulesHeader(Color color) {
    return TextStyle(
      fontSize: 30.sp,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle chatUserNameStyle(Color color) {
    return TextStyle(
      fontSize: 40.sp,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}
