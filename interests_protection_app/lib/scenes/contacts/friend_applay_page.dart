import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';

import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/models/message_model.dart';
import 'package:interests_protection_app/scenes/contacts/friend_scan_page.dart';
import 'package:interests_protection_app/scenes/contacts/widgets/friend_applay_item.dart';
import 'package:interests_protection_app/scenes/contacts/widgets/friend_search_bar.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/refresh_util.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class FriendApplayPage extends StatefulWidget {
  const FriendApplayPage({Key? key}) : super(key: key);

  @override
  State<FriendApplayPage> createState() => _FriendApplayPageState();
}

class _FriendApplayPageState extends State<FriendApplayPage> {
  final RefreshUtilController _refreshController =
      RefreshUtilController(initialRefresh: true);
  final AppHomeController _appHomeController = Get.find<AppHomeController>();
  // 系统消息监听器
  late StreamSubscription? _systemStreamSubscription;
  List<FriendApplayModel> _dataList = [];

  // 同意申请
  void _agreeApplay({required FriendApplayModel applayModel}) {
    SVProgressHUD.show();
    AccountApi.agreeFriends(params: {
      "id": applayModel.eventId,
      "agree": true,
    }).then((value) async {
      applayModel.applayState = 1;
      debugPrint("更新消息 111:${DateTime.now()}");
      await _appHomeController.accountDB!.update(
        // 更新消息
        kAppMessageTableName,
        {"isReaded": 1},
        where:
            "eventName = 'system' AND action = 'friend_apply' AND eventId = '${applayModel.eventId}'",
      );
      debugPrint("更新消息 222:${DateTime.now()}");

      setState(() {
        _appHomeController.messageHandler.add({
          StreamActionType.system:
              MessageModel.fromJson({"action": "friend_apply_update"})
        });

        SVProgressHUD.dismiss();
      });
    }).catchError((error) {
      SVProgressHUD.dismiss();
    });
  }

  // 删除申请
  void _deleteApplay({required FriendApplayModel applayModel}) async {
    void _deleteAction() async {
      await _appHomeController.accountDB!.delete(
        kAppMessageTableName,
        where:
            "eventName = 'system' AND action = 'friend_apply' AND eventId = '${applayModel.eventId}'",
      );

      _dataList.remove(applayModel);
      if (_dataList.length == 0) {
        _refreshController.status = RefreshUtilStatus.emptyData;
      }

      setState(() {
        SVProgressHUD.dismiss();

        _appHomeController.messageHandler.add({
          StreamActionType.system:
              MessageModel.fromJson({"action": "friend_apply_remove"})
        });
      });
    }

    SVProgressHUD.show();
    if (applayModel.applayState == 1) {
      _deleteAction();
    } else {
      AlertVeiw.show(
        context,
        confirmText: "确定",
        cancelText: "取消",
        contentText: "是否删除改好友申请?",
        confirmAction: () {
          AccountApi.agreeFriends(params: {
            "id": applayModel.eventId,
            "agree": false,
          }).then((value) {
            _deleteAction();
          }).catchError((error) {
            SVProgressHUD.dismiss();
          });
        },
      );
    }
  }

  // 好友申请记录列表
  Future<void> _loadRecords() async {
    Completer<void> _completer = Completer();

    _dataList.clear();
    List _recordList = await _appHomeController.accountDB!.query(
      kAppMessageTableName,
      where:
          "eventName = 'system' AND action = 'friend_apply' AND isReaded = '0'",
    );

    for (var i = 0; i < _recordList.length; i++) {
      var record = _recordList[i];
      MessageModel _recordModel = MessageModel.fromJson(record);

      FriendApplayModel _applayModel = FriendApplayModel.fromJson({});
      _applayModel.applayState = _recordModel.isReaded;
      _applayModel.userId = _recordModel.fromId;
      _applayModel.time = _recordModel.time;
      _applayModel.eventId = _recordModel.eventId;

      // 用户头像
      List _accountList = await _appHomeController.accountDB!.query(
        kAppFriendTableName,
        where: "userId = '${_applayModel.userId}'",
        limit: 1,
        columns: ["avatar", "nickname", "remark"],
      );

      if (_accountList.length > 0) {
        _applayModel.avatar = _accountList.first["avatar"];
        _applayModel.nickname = _accountList.first["remark"].length == 0
            ? _accountList.first["nickname"]
            : _accountList.first["remark"];
      }

      _dataList.add(_applayModel);

      if (i == _recordList.length - 1) {
        _completer.complete();
        _refreshController.refreshCompleted();
        setState(() {});
      }
    }

    if (_recordList.length == 0) {
      _completer.complete();
      _refreshController.refreshCompleted();
      _refreshController.status = RefreshUtilStatus.emptyData;
      setState(() {});
    }

    return _completer.future;
  }

  @override
  void initState() {
    super.initState();

    // 系统消息监听
    _systemStreamSubscription =
        _appHomeController.messageHandler.stream.listen((event) {
      var _object = event[StreamActionType.system]!;
      if (_object is MessageModel) {
        if (_object.action == "friend_apply") {
          _refreshController.requestRefresh();
        }
      }
    });
  }

  @override
  void dispose() {
    _systemStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("新的好友"),
        leading: AppbarBack(),
        actions: [
          MaterialButton(
            onPressed: () {
              Get.to(
                FriendScanPage(),
                transition: Transition.downToUp,
                popGesture: false,
                fullscreenDialog: true,
              );
            },
            minWidth: 44.w,
            height: 44.w,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(44.w / 2),
            ),
            child: Image.asset(
              "images/contacts_scan@2x.png",
              width: 24.w,
              height: 24.w,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          FriendSearchBar(),
          Expanded(
            child: RefreshUtilWidget(
              refreshController: _refreshController,
              onRefresh: _loadRecords,
              onLoadMore: null,
              child: GridView.builder(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  10.w,
                  11.w,
                  10.w,
                  MediaQuery.of(context).padding.bottom + 11.w,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 112.w / 160.w,
                  mainAxisSpacing: 10.w,
                  crossAxisSpacing: 10.w,
                ),
                itemBuilder: (context, index) {
                  FriendApplayModel applayModel = _dataList[index];
                  return FriendApplayItem(
                    applayModel: applayModel,
                    applayAction: () {
                      _agreeApplay(applayModel: applayModel);
                    },
                    deleteAction: () {
                      _deleteApplay(applayModel: applayModel);
                    },
                  );
                },
                itemCount: _dataList.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
