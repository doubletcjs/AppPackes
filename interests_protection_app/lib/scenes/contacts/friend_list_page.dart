import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';

import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/scenes/contacts/friend_scan_page.dart';
import 'package:interests_protection_app/scenes/contacts/widgets/friend_list_item.dart';
import 'package:interests_protection_app/scenes/contacts/widgets/friend_search_bar.dart';
import 'package:interests_protection_app/utils/refresh_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class FriendListPage extends StatefulWidget {
  final void Function(FriendModel friendModel)? selectionFeedback;
  const FriendListPage({
    Key? key,
    this.selectionFeedback,
  }) : super(key: key);

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  final RefreshUtilController _refreshController =
      RefreshUtilController(initialRefresh: true);
  final AppHomeController _appHomeController = Get.find<AppHomeController>();
  late StreamSubscription? _systemStreamSubscription;
  List<FriendModel> _dataList = [];

  // 删除好友
  void _friendDelete(FriendModel model) {
    void _cleanAction() async {
      // 更新好友列表
      var _list = jsonDecode(_appHomeController.accountModel.friends);
      List _friends = List.from(_list.runtimeType == String
          ? ("$_list".length == 0 ? [] : jsonDecode(_list))
          : _list);
      _friends.removeWhere((element) => element["id"] == model.userId);

      await _appHomeController.accountDB!.update(
        kAppAccountTableName,
        {"friends": jsonEncode(_friends)},
        where: "userId = '${_appHomeController.accountModel.userId}'",
      );

      _appHomeController.accountModel.friends = jsonEncode(_friends);

      // 标记好友删除
      await _appHomeController.accountDB!.update(
        kAppFriendTableName,
        {"key": "delete"},
        where: "userId = '${model.userId}'",
      );

      // 清空好友消息记录
      StorageUtils.cleanFriendChatRecord(model.userId).then((fromId) {});

      _dataList.removeWhere((element) => element.userId == model.userId);
      if (_dataList.length == 0) {
        _refreshController.status = RefreshUtilStatus.emptyData;
      }

      setState(() {
        SVProgressHUD.dismiss();
      });
    }

    AlertVeiw.show(
      context,
      confirmText: "确认",
      contentText: "是否删除该好友？并清空聊天记录!",
      cancelText: "取消",
      confirmAction: () {
        SVProgressHUD.show();
        AccountApi.friendDelete(id: model.userId).then((value) {
          _cleanAction();
        }).catchError((error) {
          SVProgressHUD.dismiss();
        });
      },
    );
  }

  // 好友申请记录列表
  Future<void> _loadRecords() async {
    Completer<void> _completer = Completer();

    _dataList.clear();
    var _list = jsonDecode(_appHomeController.accountModel.friends);
    List _friendList = List.from(_list.runtimeType == String
        ? ("$_list".length == 0 ? [] : jsonDecode(_list))
        : _list);

    String _where = "";
    _friendList.forEach((element) {
      if (_where == "") {
        _where = "userId = '${element['id']}'";
      } else {
        _where += " OR userId = '${element['id']}'";
      }
    });

    // 好友信息
    List _friends = _where.length > 0
        ? await _appHomeController.accountDB!.query(
            kAppFriendTableName,
            where: _where,
            columns: [
              "userId",
              "key",
              "remark",
              "mobile",
              "nickname",
              "avatar",
              "tags",
              "risk",
            ],
          )
        : [];

    for (var i = 0; i < _friends.length; i++) {
      _dataList.add(FriendModel.fromJson(_friends[i]));
      if (i == _friends.length - 1) {
        _completer.complete();
        _refreshController.refreshCompleted();
        setState(() {});
      }
    }

    if (_friends.length == 0) {
      _completer.complete();
      _refreshController.refreshCompleted();
      setState(() {});

      _refreshController.status = RefreshUtilStatus.emptyData;
    }

    return _completer.future;
  }

  @override
  void initState() {
    super.initState();

    // 好友信息更新通知
    _systemStreamSubscription =
        _appHomeController.messageHandler.stream.listen((event) {
      if (event.containsKey(StreamActionType.system)) {
        var _object = event[StreamActionType.system]!;
        if (_object == SystemStreamActionType.friendAdd) {
          _refreshController.requestRefresh();
        } else if (_object is FriendModel) {
          FriendModel? _friendModel = _dataList
              .firstWhereOrNull((element) => element.userId == _object.userId);
          if (_friendModel != null) {
            // 好友消息更新
            _friendModel.avatar = _object.avatar;
            _friendModel.nickname = _object.nickname;
            _friendModel.key = _object.key;
            _friendModel.remark = _object.remark;
            _friendModel.risk = _object.risk;
          } else {
            _dataList.add(_object);
          }

          setState(() {});
        } else if (_object is List<FriendModel>) {
          for (var i = 0; i < _object.length; i++) {
            FriendModel _friendModel = _object[i];
            // 好友消息更新
            FriendModel? _model = _dataList.firstWhereOrNull(
                (model) => model.userId == _friendModel.userId);
            if (_model != null) {
              _model.key = _friendModel.key;
              _model.avatar = _friendModel.avatar;
              _model.nickname = _friendModel.nickname;
              _model.remark = _friendModel.remark;
              _model.risk = _friendModel.risk;
            }

            if (i == _object.length - 1) {
              setState(() {});
            }
          }
        }
      } else if (event.containsKey(StreamActionType.friendDelete)) {
        // 删除单个好友聊天会话
        _dataList.removeWhere((element) =>
            element.userId == "${event[StreamActionType.friendDelete]!}");
        setState(() {
          if (_dataList.length == 0) {
            _refreshController.status = RefreshUtilStatus.emptyData;
          }
        });
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
        title: Text("我的好友"),
        leading: AppbarBack(),
        actions: widget.selectionFeedback != null
            ? []
            : [
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
          widget.selectionFeedback != null ? SizedBox() : FriendSearchBar(),
          Expanded(
            child: RefreshUtilWidget(
              refreshController: _refreshController,
              onRefresh: _loadRecords,
              onLoadMore: null,
              child: ListView.builder(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                itemBuilder: (context, index) {
                  FriendModel model = _dataList[index];
                  return Slidable(
                    key: ValueKey("friend_$index"),
                    child: FriendListItem(
                      friendModel: model,
                      feedback: () {
                        if (widget.selectionFeedback != null) {
                          widget.selectionFeedback!(model);

                          Get.back();
                        } else {
                          try {
                            Get.toNamed(RouteNameString.chat,
                                arguments: {"fromId": model.userId});
                          } catch (e) {}
                        }
                      },
                    ),
                    endActionPane: ActionPane(
                      motion: ScrollMotion(),
                      extentRatio: 0.2,
                      children: [
                        SlidableAction(
                          flex: 12,
                          backgroundColor: kAppConfig.appThemeColor,
                          padding: EdgeInsets.zero,
                          onPressed: (context) {
                            _friendDelete(model);
                          },
                          icon: Icons.delete,
                          label: "删除",
                        ),
                      ],
                    ),
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
