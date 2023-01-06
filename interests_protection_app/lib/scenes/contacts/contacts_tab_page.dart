import 'dart:async';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/models/chat_record_model.dart';
import 'package:interests_protection_app/models/conversation_model.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/models/message_model.dart';
import 'package:interests_protection_app/scenes/contacts/friend_applay_page.dart';
import 'package:interests_protection_app/scenes/contacts/friend_list_page.dart';
import 'package:interests_protection_app/scenes/contacts/friend_scan_page.dart';
import 'package:interests_protection_app/scenes/contacts/friend_search_page.dart';
import 'package:interests_protection_app/scenes/contacts/friend_tag_manager.dart';
import 'package:interests_protection_app/scenes/contacts/widgets/contacts_list_item.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/refresh_util.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';

class ContactsTabPage extends StatefulWidget {
  ContactsTabPage({Key? key}) : super(key: key);

  @override
  State<ContactsTabPage> createState() => _ContactsTabPageState();
}

class _ContactsTabPageState extends State<ContactsTabPage>
    with AutomaticKeepAliveClientMixin {
  final RefreshUtilController _refreshController =
      RefreshUtilController(initialRefresh: true);
  final AppHomeController _appHomeController = Get.find<AppHomeController>();
  // 系统消息监听器
  late StreamSubscription? _systemStreamSubscription;
  // 聊天消息监听器
  late StreamSubscription? _chatStreamSubscription;

  int _newFriendCount = 0;
  List<ConversationModel> _dataSources = [];

  // 热门标签
  Widget _contactsLabelBar() {
    final List<String> _hotLabelList = [
      "新的好友",
      "我的好友",
      "标签",
    ];

    final List<String> _labelIconsList = [
      "images/contacts_label@2x.png",
      "images/contacts_label_my@2x.png",
      "images/contacts_label_new@2x.png",
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
      ),
      child: Column(
        children: [
          Container(
            height: 103.w,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_hotLabelList.length, (index) => index)
                  .map((index) {
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 69.w),
                  child: InkWell(
                    onTap: () {
                      if (index == 0) {
                        Get.to(FriendApplayPage());
                      } else if (index == 1) {
                        Get.to(FriendListPage());
                      } else if (index == 2) {
                        Get.to(FriendTagManager());
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              _labelIconsList[index],
                              width: 50.w,
                              height: 50.w,
                            ),
                            SizedBox(height: 8.w),
                            Text(
                              _hotLabelList[index],
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          ],
                        ),
                        index == 0 && _newFriendCount > 0
                            ? Positioned(
                                top: 15.w,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: kAppConfig.appThemeColor,
                                    borderRadius:
                                        BorderRadius.circular(20.w / 2),
                                    border: Border.all(
                                      width: 1.w,
                                      color: const Color(0xFFFFFFFF),
                                    ),
                                  ),
                                  constraints: BoxConstraints(
                                      minHeight: 15.w, minWidth: 15.w),
                                  padding: EdgeInsets.fromLTRB(
                                    5.w,
                                    2.w,
                                    5.w,
                                    2.w,
                                  ),
                                  child: Text(
                                    "$_newFriendCount",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: const Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ))
                            : SizedBox(),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            height: 14.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.w),
                topRight: Radius.circular(20.w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 创建会话
  Future<ConversationModel> _conversationCreation(String fromId) async {
    Completer<ConversationModel> _completer = Completer();
    ConversationModel _conversationModel;

    void _emptyConversation() async {
      // 好友信息
      Future<FriendModel> _loadFriend(String fromId) async {
        List _friends = await _appHomeController.accountDB!.query(
          kAppFriendTableName,
          where: "userId = '$fromId'",
          limit: 1,
          columns: [
            "userId",
            "remark",
            "nickname",
            "avatar",
            "key",
            "risk",
          ],
        );

        FriendModel _friendModel = FriendModel.fromJson({});
        if (_friends.length > 0) {
          _friendModel = FriendModel.fromJson(_friends.first ?? {});
        }

        return _friendModel;
      }

      _conversationModel = ConversationModel.fromJson({});
      _conversationModel.fromId = fromId;
      _conversationModel.lastContent = "";
      _conversationModel.lastContentId = "";
      _conversationModel.unread = 0;
      _conversationModel.lastTime =
          DateUtil.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
      _conversationModel.friendModel = await _loadFriend(fromId);

      _completer.complete(_conversationModel);
    }

    try {
      String _sql = """SELECT $kAppChatRecordTableName.*,
          $kAppFriendTableName.userId,$kAppFriendTableName.remark,$kAppFriendTableName.nickname,$kAppFriendTableName.key,$kAppFriendTableName.avatar
        FROM '$kAppChatRecordTableName' LEFT JOIN '$kAppFriendTableName'  
        on $kAppChatRecordTableName.fromId = $kAppFriendTableName.userId 
        WHERE eventName = 'chat' AND fromId = '$fromId' 
        ORDER BY time DESC
        LIMIT 1""";
      List<Map<String, dynamic>> _recordList =
          await _appHomeController.accountDB!.rawQuery(_sql);
      if (_recordList.length > 0) {
        var _value = Map<String, dynamic>.from(_recordList[0]);
        _value.remove("id");

        ChatRecordModel _recordModel = ChatRecordModel.fromJson(_value);
        // 最后一条消息
        String _lastContent() {
          if (_recordModel.action == "friend_add") {
            return "你已经添加该好友，现在可以开始聊天了。";
          }

          if (_recordModel.action == "risk_warn") {
            return "[账号异常]";
          }

          if (_recordModel.action == "lose" ||
              (_recordModel.decrypt == 1 && _recordModel.isMine == 0)) {
            return "消息已过期";
          }

          if (_recordModel.action == "file") {
            String _fileName = _recordModel.filename.replaceAll("\n", "");
            if (_fileName.length == 0) {
              _fileName = _recordModel.content;
            }

            String _fileType = "[文件]$_fileName";
            if (_fileName.toLowerCase().contains(".jpg") ||
                _fileName.toLowerCase().contains(".png") ||
                _fileName.toLowerCase().contains(".jpeg") ||
                _fileName.toLowerCase().contains(".gif")) {
              _fileType = "[图片]";
            }

            return _fileType;
          }

          return _recordModel.content;
        }

        // 未读消息数
        Future<int> _unreadCount(String fromId) async {
          List _list = await _appHomeController.accountDB!.query(
            kAppChatRecordTableName,
            where:
                "eventName = 'chat' AND fromId = '$fromId' AND isReaded = '0'", // 剔除新加好友 AND action != 'friend_add'
            columns: ["id"],
          );

          return _list.length;
        }

        _conversationModel = ConversationModel.fromJson({});
        _conversationModel.fromId = _recordModel.fromId;
        _conversationModel.lastTime = _recordModel.time;
        _conversationModel.lastContent = _lastContent();
        _conversationModel.lastContentId = _recordModel.eventId;
        _conversationModel.unread = await _unreadCount(_recordModel.fromId);
        _conversationModel.friendModel = FriendModel.fromJson(_value);
        if (_conversationModel.friendModel?.userId.length == 0) {
          _conversationModel.friendModel?.userId = _recordModel.fromId;
        }

        _completer.complete(_conversationModel);
      } else {
        _emptyConversation();
      }
    } catch (e) {
      debugPrint("创建会话:$e");
      utilsToast(msg: "$e");
      _emptyConversation();
    }

    return _completer.future;
  }

  // 读取会话记录列表
  Future<void> _loadRecords() async {
    Completer<void> _completer = Completer();
    _dataSources.clear();

    // 读取所有聊天会话
    try {
      String _sql = """SELECT $kAppConversationTableName.*,
          $kAppFriendTableName.userId,$kAppFriendTableName.remark,$kAppFriendTableName.nickname,$kAppFriendTableName.key,$kAppFriendTableName.avatar
        FROM '$kAppConversationTableName' LEFT JOIN '$kAppFriendTableName'  
        on $kAppConversationTableName.fromId = $kAppFriendTableName.userId 
        GROUP BY fromId
        ORDER BY lastTime DESC""";
      List<Map<String, dynamic>> _conversationRecordList =
          await _appHomeController.accountDB!.rawQuery(_sql);

      if (_conversationRecordList.length == 0) {
        List<Map> result = await _appHomeController.accountDB!.rawQuery(
          "SELECT seq FROM sqlite_sequence WHERE name = '$kAppConversationTableName'",
        );

        if (result.length == 0 || result.first["seq"] == 0) {
          debugPrint("迁移聊天会话记录");
          List _recordList = await _appHomeController.accountDB!.query(
            kAppChatRecordTableName,
            where: "eventName = 'chat'",
            groupBy: "fromId",
            columns: ["fromId"],
          );

          for (var i = 0; i < _recordList.length; i++) {
            ChatRecordModel _recordModel =
                ChatRecordModel.fromJson(_recordList[i]);
            if (_recordModel.fromId.length > 0) {
              ConversationModel _model =
                  await _conversationCreation(_recordModel.fromId);
              _dataSources.add(_model);

              _appHomeController.accountDB?.insert(
                kAppConversationTableName,
                _model.toJson(),
              );
            }

            if (i == _recordList.length - 1) {
              _completer.complete();
            }
          }

          if (_recordList.length == 0) {
            _completer.complete();
          }
        } else {
          _completer.complete();
        }
      } else {
        List<String> _fromIdList = [];
        for (var i = 0; i < _conversationRecordList.length; i++) {
          Map<String, dynamic> _value =
              Map<String, dynamic>.from(_conversationRecordList[i]);
          _value.remove("id");

          ConversationModel _recordModel = ConversationModel.fromJson(_value);
          _recordModel.friendModel = FriendModel.fromJson(_value);
          _dataSources.add(_recordModel);
          _fromIdList.add(_recordModel.fromId);

          if (i == _conversationRecordList.length - 1) {
            _updateChatConversation(_fromIdList);
            _completer.complete();
          }
        }

        if (_conversationRecordList.length == 0) {
          _completer.complete();
        }
      }
    } catch (e) {
      utilsToast(msg: "$e");
      _completer.complete();
    }

    return _completer.future;
  }

  // 刷新数据
  void _refresh() {
    // 好友申请记录
    _friendApplayState();

    _loadRecords().then((value) {
      if (_dataSources.length == 0) {
        _refreshController.refreshCompleted();
        _refreshController.status = RefreshUtilStatus.emptyData;
        setState(() {});
      } else {
        setState(() {
          _refreshController.refreshCompleted();
        });

        Future.delayed(Duration(milliseconds: 200), () {
          _loadUndecryptRecord();
        });
      }
    });
  }

  // 没解密的消息
  void _loadUndecryptRecord() {
    // 更新解密状态
    _appHomeController.accountDB!
        .query(
      kAppChatRecordTableName,
      where: "eventName = 'chat' AND decrypt = '0' AND isMine = '0'",
    )
        .then((list) async {
      List<ChatRecordModel> _recordList = [];
      for (var i = 0; i < list.length; i++) {
        ChatRecordModel _model = ChatRecordModel.fromJson(list[i]);
        if (_model.action != "friend_add") {
          List _friendList = await _appHomeController.accountDB!.query(
            kAppFriendTableName,
            where: "userId = '${_model.fromId}' AND updateState = '1'",
            columns: ["key"],
            limit: 1,
          );

          if (_friendList.length > 0) {
            _model.publicKey = _friendList.first["key"];
            if (_model.encryptSources.length == 0) {
              // 记录加密源
              if (_model.action == "file") {
                _model.encryptSources = _model.filename;
              } else {
                _model.encryptSources = _model.content;
              }
            }
            _recordList.add(_model);
          }
        }
      }
    });
  }

  // 未处理好友申请数
  void _friendApplayState() async {
    _appHomeController.accountDB!.query(
      kAppMessageTableName,
      where:
          "eventName = 'system' AND action = 'friend_apply' AND isReaded = '0'",
      columns: ["id"],
    ).then((value) {
      if (_newFriendCount != value.length) {
        _newFriendCount = value.length;
        setState(() {});
      }
    });
  }

  // 更新聊天会话
  void _updateChatConversation(List<String> fromIdList) async {
    for (var i = 0; i < fromIdList.length; i++) {
      String fromId = fromIdList[i];
      if (fromId.length > 0) {
        ConversationModel? _model = _dataSources
            .firstWhereOrNull((element) => element.fromId == fromId);
        ConversationModel? _newModel = await _conversationCreation(fromId);
        if (_model == null) {
          // 新增
          _dataSources.insert(0, _newModel);

          await _appHomeController.accountDB!.insert(
            kAppConversationTableName,
            _newModel.toJson(),
          );
        } else {
          // 更新
          List<ConversationModel> _tempDataSources =
              List<ConversationModel>.from(_dataSources);
          _tempDataSources.removeWhere((element) => element.fromId == fromId);
          _tempDataSources.insert(0, _newModel);
          _dataSources = List<ConversationModel>.from(_tempDataSources);

          _appHomeController.accountDB!.update(
            kAppConversationTableName,
            _newModel.toJson(),
            where: "fromId = '$fromId'",
          );
        }

        if (i == fromIdList.length - 1) {
          if (_dataSources.length == 0) {
            _refreshController.status = RefreshUtilStatus.emptyData;
          } else {
            _refreshController.status = RefreshUtilStatus.normal;
          }

          setState(() {});
        }
      }
    }
  }

  // 已读
  void _readConversation(String fromId) async {
    ConversationModel? _model =
        _dataSources.firstWhereOrNull((element) => element.fromId == fromId);
    if (_model != null) {
      _model.unread = 0;

      setState(() {});
    }
  }

  // 系统消息监听处理
  void _systemHandler(Map<StreamActionType, dynamic> event) {
    void _updateFriend(FriendModel friendModel, void Function() finish) {
      int _index = _dataSources
          .indexWhere((element) => element.fromId == friendModel.userId);
      if (_index > -1) {
        ConversationModel _model = _dataSources[_index];
        _model.friendModel!.key = friendModel.key;
        _model.friendModel!.avatar = friendModel.avatar;
        _model.friendModel!.nickname = friendModel.nickname;
        _model.friendModel!.remark = friendModel.remark;
        _model.friendModel!.risk = friendModel.risk;

        if (_model.friendModel!.timeout != friendModel.timeout) {
          _model.friendModel!.timeout = friendModel.timeout;
        }

        _dataSources[_index] = _model;
        finish();
      }
    }

    if (event.containsKey(StreamActionType.system)) {
      var _object = event[StreamActionType.system]!;
      if (_object is MessageModel) {
        MessageModel _model = _object;
        // 好友申请
        if (_model.action == "friend_apply" ||
            _model.action == "friend_apply_remove" ||
            _model.action == "friend_apply_update") {
          _friendApplayState();
        } else if (_model.action == "readed") {
          // 消息已读
          _readConversation(_model.fromId);
        }
      } else if (_object is FriendModel) {
        FriendModel _friendModel = _object;
        // 好友消息更新
        _updateFriend(_friendModel, () {
          setState(() {
            _loadUndecryptRecord();
          });
        });
      } else if (_object is List<FriendModel>) {
        for (var i = 0; i < _object.length; i++) {
          FriendModel _friendModel = _object[i];
          // 好友消息更新
          _updateFriend(_friendModel, () {
            if (i == _object.length - 1) {
              setState(() {
                _loadUndecryptRecord();
              });
            }
          });
        }
      } else if (_object == SystemStreamActionType.emptyMessage) {
        // 清空聊天记录
        _refreshController.requestRefresh();
      }
    } else if (event.containsKey(StreamActionType.cleanMessage)) {
      // 删除单个好友聊天会话
      _updateChatConversation(["${event[StreamActionType.cleanMessage]!}"]);
    } else if (event.containsKey(StreamActionType.messageDestroy)) {
      var _object = event[StreamActionType.messageDestroy]!;
      if (_object is Map) {
        _updateChatConversation(["${_object["fromId"]}"]);
      } else if (_object is List) {
        // 删除批量消息
        List<String> fromIdList = [];
        for (var i = 0; i < _object.length; i++) {
          var data = _object[i];
          fromIdList.add(data["fromId"]);
          if (i == _object.length - 1) {
            _updateChatConversation(fromIdList);
          }
        }
      }
    }
  }

  // 聊天消息监听处理
  void _chatHandler(Map<StreamActionType, dynamic> event) {
    if (event.containsKey(StreamActionType.chat) ||
        event.containsKey(StreamActionType.sendChat)) {
      StreamActionType _actionType = event.keys.first;
      if (event[_actionType] is List<ChatRecordModel>) {
        List<ChatRecordModel> _list = event[_actionType];
        _updateChatConversation(
            List.generate(_list.length, (index) => index).map((index) {
          return _list[index].fromId;
        }).toList());
      } else {
        ChatRecordModel _model = event[_actionType];
        _updateChatConversation([_model.fromId]);
      }
    }
  }

  // 删除好友
  void _conversationDelete(ConversationModel model) {
    AlertVeiw.show(
      context,
      confirmText: "确认",
      contentText: "是否删除该会话？",
      cancelText: "取消",
      confirmAction: () async {
        int _raw = await _appHomeController.accountDB!.delete(
          kAppConversationTableName,
          where: "fromId = '${model.fromId}'",
        );

        if (_raw == 1) {
          _dataSources.removeWhere((element) => element.fromId == model.fromId);
          if (_dataSources.length == 0) {
            _refreshController.status = RefreshUtilStatus.emptyData;
          }
          setState(() {});
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // 系统消息监听
    _systemStreamSubscription =
        _appHomeController.messageHandler.stream.listen((event) {
      debugPrint("会话列表系统消息监听");
      _systemHandler(event);
    });

    // 聊天消息监听器
    _chatStreamSubscription =
        _appHomeController.chatHandler.stream.listen((event) {
      debugPrint("会话列表聊天消息监听器");
      _chatHandler(event);
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _systemStreamSubscription?.cancel();
    _chatStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 52.w,
        leading: Center(
          child: MaterialButton(
            onPressed: () {
              Get.to(
                FriendSearchPage(),
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
              "images/contacts_search@2x.png",
              width: 22.w,
              height: 32.w,
            ),
          ),
        ),
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
          _refreshController.status == RefreshUtilStatus.normal
              ? SizedBox()
              : _contactsLabelBar(),
          Expanded(
            child: RefreshUtilWidget(
              refreshController: _refreshController,
              onRefresh: _refresh,
              child: ListView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 15.w),
                shrinkWrap: true,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                children: [
                  _refreshController.status == RefreshUtilStatus.normal
                      ? _contactsLabelBar()
                      : SizedBox(),
                  ...List.generate(_dataSources.length, (index) => index)
                      .map((index) {
                    return Slidable(
                      key: ValueKey("conversation_$index"),
                      endActionPane: ActionPane(
                        motion: ScrollMotion(),
                        extentRatio: 0.2,
                        children: [
                          SlidableAction(
                            flex: 12,
                            backgroundColor: kAppConfig.appThemeColor,
                            padding: EdgeInsets.zero,
                            onPressed: (context) {
                              _conversationDelete(_dataSources[index]);
                            },
                            icon: Icons.delete,
                            label: "删除",
                          ),
                        ],
                      ),
                      child: ContactsListItem(
                        model: _dataSources[index],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
