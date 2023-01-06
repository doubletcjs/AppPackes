import 'dart:async';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/apis/message_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';

import 'package:interests_protection_app/controllers/personal_data_controller.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/scenes/contacts/remark_tag_page.dart';
import 'package:interests_protection_app/scenes/personal/widgets/personal_list_item.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class ChatSettingPage extends StatefulWidget {
  final FriendModel friendModel;
  const ChatSettingPage({super.key, required this.friendModel});

  @override
  State<ChatSettingPage> createState() => _ChatSettingPageState();
}

class _ChatSettingPageState extends State<ChatSettingPage> {
  AppHomeController _appHomeController = Get.find<AppHomeController>();
  // 系统消息监听器
  late StreamSubscription? _systemSubscription;

  // 清空记录
  void _cleanMessage(bool bothSide) {
    SVProgressHUD.show();

    StorageUtils.cleanFriendChatRecord(widget.friendModel.userId)
        .then((fromId) {
      if (fromId.length > 0) {
        if (bothSide == true) {
          // 上报消息事件id
          MessageApi.report(params: {
            "data": widget.friendModel.userId,
            "type": "destroy_friend",
          }).then((value) {
            SVProgressHUD.dismiss();
          }).catchError((error) {
            SVProgressHUD.dismiss();
          });
        } else {
          Future.delayed(Duration(milliseconds: 300), () {
            SVProgressHUD.dismiss();
          });
        }
      } else {
        SVProgressHUD.dismiss();
      }
    });
  }

  // 销毁时间格式
  String _destroyFormat(int _destroy) {
    if (_destroy < 60) {
      return "$_destroy秒";
    } else if (_destroy >= 60 && _destroy < 60 * 60 * 24) {
      return "${(_destroy / 60 / 60).round()}小时";
    } else {
      return "${(_destroy / 60 / 60 / 24).round()}天";
    }
  }

  // 自动销毁
  void _selfDestroy(BuildContext context) {
    void _setDestroy(int second) async {
      Map<String, dynamic> _params = {"fid": widget.friendModel.userId};
      _params["timeout"] = second;

      SVProgressHUD.show();
      AccountApi.updateFriendsInfo(params: _params).then((value) async {
        // 更新用户信息数据库
        widget.friendModel.timeoutDate =
            DateUtil.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");

        await _appHomeController.accountDB!.update(
          kAppFriendTableName,
          {"timeout": second, "timeoutDate": widget.friendModel.timeoutDate},
          where: "userId = '${widget.friendModel.userId}'",
        );

        widget.friendModel.timeout = second;
        setState(() {
          try {
            Get.find<PersonalDataController>().launchMessageDestroy();
          } catch (e) {}
        });

        SVProgressHUD.dismiss();
      }).catchError((error) {
        SVProgressHUD.dismiss();
      });
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              child: const Text("20秒"),
              onPressed: () {
                Navigator.pop(context);

                _setDestroy(20);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("1小时"),
              onPressed: () {
                Navigator.pop(context);
                _setDestroy(60 * 60);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("3天"),
              onPressed: () {
                Navigator.pop(context);
                _setDestroy(60 * 60 * 24 * 3);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text("取消"),
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // 系统通知
    _systemSubscription =
        _appHomeController.messageHandler.stream.listen((event) {
      if (event.containsKey(StreamActionType.friendDelete)) {
        // 删除好友
        var _fromId = event[StreamActionType.friendDelete]!;
        if (_fromId == widget.friendModel.userId) {
          Get.back();
        }
      } else if (event.containsKey(StreamActionType.system)) {
        var _object = event[StreamActionType.system]!;
        if (_object is FriendModel) {
          FriendModel _friendModel = _object;
          // 好友消息更新
          if (_friendModel.userId == widget.friendModel.userId) {
            setState(() {});
          }
        } else if (_object is List<FriendModel>) {
          FriendModel? _friendModel = _object
              .firstWhereOrNull((element) => element.userId == element.userId);
          if (_friendModel != null &&
              _friendModel.userId == widget.friendModel.userId) {
            setState(() {});
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _systemSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("聊天设置"),
        leading: AppbarBack(),
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: [
          Container(
            margin: EdgeInsets.only(top: 14.w),
            child: PersonalListItem(
              leading: Text(
                "昵称",
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 15.sp,
                ),
              ),
              height: 56.w,
              hideBorder: true,
              actionWidget: Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: Text(
                  "${widget.friendModel.nickname}",
                  style: TextStyle(
                    color: const Color(0xFFB3B3B3),
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 14.w, bottom: 14.w),
            child: PersonalListItem(
              leading: Text(
                "备注和标签",
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 15.sp,
                ),
              ),
              labelAction: () {
                Get.to(
                  RemarkTagPage(friendModel: widget.friendModel),
                  transition: Transition.downToUp,
                  popGesture: false,
                  fullscreenDialog: true,
                );
              },
              height: 56.w,
              hideBorder: true,
            ),
          ),
          Column(
            children: [
              _appHomeController.accountModel.level == 0
                  ? SizedBox()
                  : PersonalListItem(
                      leading: Text(
                        "阅后即焚",
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 15.sp,
                        ),
                      ),
                      actionWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 160.w),
                            child: Text(
                              widget.friendModel.timeout == 0
                                  ? "不设置"
                                  : _destroyFormat(widget.friendModel.timeout),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFFB3B3B3),
                                fontSize: 15.sp,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          SizedBox(width: 7.w),
                          Image.asset(
                            "images/personal_arrow@2x.png",
                            width: 24.w,
                            height: 24.w,
                          ),
                        ],
                      ),
                      labelAction: () {
                        _selfDestroy(context);
                      },
                      height: 56.w,
                    ),
              PersonalListItem(
                leading: Text(
                  "清空本地聊天记录",
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 15.sp,
                  ),
                ),
                labelAction: () {
                  AlertVeiw.show(
                    context,
                    confirmText: "确认",
                    contentText: "是否清空与该好友的本地聊天记录?",
                    cancelText: "取消",
                    confirmAction: () {
                      _cleanMessage(false);
                    },
                  );
                },
                height: 56.w,
              ),
              _appHomeController.accountModel.level == 0
                  ? SizedBox()
                  : PersonalListItem(
                      leading: Text(
                        "双向清空聊天记录",
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 15.sp,
                        ),
                      ),
                      labelAction: () {
                        AlertVeiw.show(
                          context,
                          confirmText: "确认",
                          contentText: "是否清空与该好友的本地聊天记录，同时清空对方聊天记录?",
                          cancelText: "取消",
                          confirmAction: () {
                            _cleanMessage(true);
                          },
                        );
                      },
                      height: 56.w,
                      hideBorder: true,
                    ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 14.w),
            color: const Color(0xFFFFFFFF),
            child: MaterialButton(
              onPressed: () {
                Get.back();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              height: 56.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "images/chat_comment@2x.png",
                    width: 18.w,
                    height: 18.w,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "发消息",
                    style: TextStyle(
                      color: const Color(0xFF3A587A),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
