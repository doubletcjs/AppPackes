import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class NewsImageItem extends StatelessWidget {
  const NewsImageItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () {},
      padding: EdgeInsets.fromLTRB(27.w, 16.w, 20.w, 16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: networkImage(
        "",
        Size(MediaQuery.of(context).size.width, 95.w),
        BorderRadius.circular(10.w),
      ),
    );
  }
}
