import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';

import 'package:interests_protection_app/models/conversation_model.dart';
import 'package:interests_protection_app/models/message_model.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/utils/local_notification.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:objectid/objectid.dart';

class ContactsListItem extends StatelessWidget {
  final ConversationModel model;
  const ContactsListItem({
    Key? key,
    required this.model,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          MaterialButton(
            onPressed: () {
              try {
                if (model.friendModel?.key.length == 0) {
                  utilsToast(msg: "对方不在线");
                } else if (model.friendModel?.key == "delete") {
                  utilsToast(msg: "对方已不是你的好友");
                } else {
                  Get.toNamed(RouteNameString.chat, arguments: {
                    "fromId": model.fromId,
                  });
                }

                if (model.unread > 0) {
                  Get.find<AppHomeController>().messageHandler.add({
                    StreamActionType.system: MessageModel.fromJson({})
                      ..action = "readed"
                      ..fromId = model.fromId
                  });
                }

                notification.cancelNotification(
                    ObjectId.fromHexString(model.lastContentId).hashCode >> 32);
              } catch (e) {}
            },
            hoverColor: const Color(0xFFFFFFFF),
            elevation: 0,
            highlightElevation: 0,
            hoverElevation: 0,
            focusElevation: 0,
            padding: EdgeInsets.fromLTRB(18.w, 11.w, 18.w, 11.w),
            child: Row(
              children: [
                networkImage(
                  model.friendModel != null ? model.friendModel!.avatar : "",
                  Size(48.w, 48.w),
                  BorderRadius.circular(5.w),
                  memoryData: true,
                  placeholder: "images/personal_placeholder@2x.png",
                ),
                SizedBox(width: 13.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              model.friendModel != null
                                  ? (model.friendModel!.remark.length == 0
                                      ? model.friendModel!.nickname
                                      : model.friendModel!.remark)
                                  : "-",
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          ),
                          Text(
                            "${timeLineFormat(date: model.lastTime)}",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: kAppConfig.appPlaceholderColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.w),
                      Text(
                        model.friendModel?.key == "delete"
                            ? "[对方已不是你的好友]"
                            : "${model.lastContent}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: "${model.lastContent}" == "[账号异常]"
                              ? const Color(0xFFFF8D1A)
                              : const Color(0xFFB3B3B3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 未读消息数
          Positioned(
            top: 5.w,
            right: MediaQuery.of(context).size.width - 18.w - 48.w - 7.w,
            child: model.unread == 0
                ? SizedBox()
                : model.unread > 99
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15.w / 2),
                        child: Image.asset(
                          "images/contacts_more@2x.png",
                          width: 23.w,
                          height: 15.w,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: kAppConfig.appThemeColor,
                          borderRadius: BorderRadius.circular(20.w / 2),
                          border: Border.all(
                            width: 1.w,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                        constraints:
                            BoxConstraints(minHeight: 15.w, minWidth: 15.w),
                        padding: EdgeInsets.fromLTRB(
                          5.w,
                          2.w,
                          5.w,
                          1.w,
                        ),
                        child: Text(
                          "${model.unread}",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
