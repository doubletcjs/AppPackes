import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/scenes/contacts/friend_search_page.dart';

class FriendSearchBar extends StatelessWidget {
  const FriendSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(10.w, 12.w, 10.w, 12.w),
      height: 40.w,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(40.w / 2),
        border: Border.all(
          width: 0.5.w,
          color: const Color(0xFFE8E8E8),
        ),
      ),
      child: MaterialButton(
        onPressed: () {
          Get.to(
            FriendSearchPage(),
            transition: Transition.downToUp,
            popGesture: false,
            fullscreenDialog: true,
          );
        },
        padding: EdgeInsets.only(left: 14.w, right: 14.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40.w / 2),
        ),
        child: Row(
          children: [
            Image.asset(
              "images/friend_search@2x.png",
              width: 17.w,
              height: 17.w,
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Text(
                "搜索好友",
                style: TextStyle(
                  color: const Color(0xFFE9E9E9),
                  fontSize: 15.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
