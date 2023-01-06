import 'dart:async';
import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:interests_protection_app/controllers/tickets_data_controller.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/system_api.dart';
import 'package:interests_protection_app/controllers/personal_data_controller.dart';
import 'package:interests_protection_app/models/account_model.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/models/chat_record_model.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/scenes/account/pincode_input_page.dart';
import 'package:interests_protection_app/scenes/guidance/launch_guidance.dart';
import 'package:interests_protection_app/scenes/personal/real_name_auth_page.dart';
import 'package:interests_protection_app/scenes/tickets/tickets_publish_page.dart';
import 'package:interests_protection_app/service/foreground_service.dart';
import 'package:interests_protection_app/utils/local_notification.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:url_launcher/url_launcher_string.dart';

final String kAppLocationStatus = "kAppLocationStatus"; // 定位权限
final String kAppBluetoothStatus = "kAppBluetoothStatus"; // 蓝牙权限
final String kAppNotificationStatus = "kAppNotificationStatus"; // 消息权限

enum SystemStreamActionType {
  customerSwitch, //  切换客服
  customerEnd, // 客服退出
  rescueEnd, // 退出紧急救援
  friendAdd, // 添加好友
  emptyMessage, // 清空聊天会话
}

enum StreamActionType {
  customer, // 客服消息
  chat, // 聊天消息
  system, // 系统消息
  sendChat, // 本人发送信息
  messageDestroy, // 消息删除
  cleanMessage, // 删除单个好友聊天会话
  friendDelete, // 删除好友
}

enum AppCurrentState {
  init, // 未登录
  logined, // 已登录
  verifyPinCode, // 已验证PinCode
  normal, // 所有校验完成
}

class AppHomeController extends GetxController {
  late Database? accountDB; // 本地数据库
  AccountModel accountModel = AccountModel.fromJson({});
  bool xpinMode = false;

  int _sseState = -1; // -1 初始化 0 连接中 1 已连接 2 已断开
  int get sseState => _sseState;
  set sseState(int s) {
    if (s != _sseState) {
      _sseState = s;
      this.update(["kSseStateUpdate"]);
    }

    if (GetPlatform.isAndroid) {
      FlutterForegroundTask.updateService(
        notificationTitle:
            "服务${_sseState == 0 ? '连接中' : _sseState == 1 ? '已连接' : _sseState == 2 ? '已断开' : '未连接'}",
      );
    }
  }

  /// 聊天消息监听器
  StreamController<Map<StreamActionType, dynamic>> chatHandler =
      StreamController.broadcast();

  /// 系统消息监听器
  StreamController<Map<StreamActionType, dynamic>> messageHandler =
      StreamController.broadcast();

  AppCurrentState appState = AppCurrentState.init;

  /// 点击通知
  Future<void> disposeNotification() async {
    String? _data =
        (await SharedPreferences.getInstance()).getString("kNotificationData");
    dynamic notificationData;
    try {
      notificationData =
          (_data == null || _data.length == 0) ? null : jsonDecode(_data);
    } catch (e) {
      notificationData = null;
    }

    if (notificationData != null) {
      // 检测登录状态
      void _notificationOpen(String event, String fromId) {
        void _enterChat() async {
          if (event == "customer") {
            if (Get.currentRoute != "/customer") {
              try {
                Get.toNamed(RouteNameString.customer);
                notification.cleanNotification(); // 这里先清空全部通知，测试用
                (await SharedPreferences.getInstance())
                    .setString("kNotificationData", "");
              } catch (e) {}
            }
          } else if (event == "chat") {
            if (Get.currentRoute != "/chat") {
              try {
                Get.toNamed(RouteNameString.chat, arguments: {
                  "fromId": fromId,
                  "fromAlert": true,
                });
                notification.cleanNotification(); // 这里先清空全部通知，测试用
                (await SharedPreferences.getInstance())
                    .setString("kNotificationData", "");
              } catch (e) {}
            }
          }
        }

        try {
          Future.delayed(Duration(milliseconds: 100), () {
            SVProgressHUD.dismiss();
            this.onTabNotify(event == "chat" ? 3 : 2, (blockIndex, xpin) {
              _enterChat();
            });
          });
        } catch (e) {}
      }

      switch (notificationData["event"]) {
        case "customer":
          // 进入聊天页面之后应该清空客服消息推送
          _notificationOpen("customer", "");
          break;
        case "chat":
          // 进入聊天页面之后应该清空客服消息推送
          _notificationOpen("chat", notificationData["from"]);
          break;
        default:
          break;
      }
    }
  }

  /// 未读消息数
  String badgeNumber = "";
  void unreadCount() {
    if (appState != AppCurrentState.init && accountDB != null) {
      accountDB!.query(
        kAppChatRecordTableName,
        where: "eventName = 'chat' AND isReaded = '0'",
        columns: ["id"],
      ).then((chatList) {
        accountDB!.query(
          kAppMessageTableName,
          where:
              "eventName = 'system' AND action = 'friend_apply' AND isReaded = '0'",
          columns: ["id"],
        ).then((messageList) {
          String _count = (chatList.length + messageList.length > 0)
              ? "${chatList.length + messageList.length}"
              : "";
          if (_count != badgeNumber) {
            badgeNumber = _count;
            update(["kBadgeNumber"]);
          }
        });
      });
    }
  }

  /// 检测版本
  bool _versionAlert = false;
  String appVersion = "";
  void launchAert(
    BuildContext context, {
    bool getPermission = true,
    bool resume = false,
    void Function()? complete,
  }) async {
    if (_versionAlert == true) {
      return;
    }

    _versionAlert = true;
    // 版本更新
    void _alert() {
      debugPrint("版本更新");
      Future.delayed(Duration(milliseconds: 300), () {
        AlertVeiw.show(
          context,
          confirmText: "更新",
          contentText: "",
          onWillPop: false,
          contentWidget: Padding(
            padding: EdgeInsets.fromLTRB(25.w, 33.w, 25.w, 16.w),
            child: Center(
              child: Text(
                "检测到新版本,请点击下载最新版本",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF000000),
                  height: 1.5,
                ),
              ),
            ),
          ),
          confirmAction: () {
            SVProgressHUD.show();
            SystemApi.version(params: {}).then((value) {
              SVProgressHUD.dismiss();
              _versionAlert = false;

              var data = value ?? {};
              String _version = "";
              if (GetPlatform.isAndroid) {
                _version = (data["android"] ?? {})["version"] ?? "";
                if (_version.length > 0) {
                  if (_version != this.appVersion) {
                    Future.delayed(Duration(milliseconds: 10), () async {
                      await launchUrlString(
                        "https://overseas.app.tairnet.com",
                        mode: LaunchMode.externalApplication,
                      );
                    });
                  }
                }
              }
            }).catchError((error) {
              _versionAlert = false;
              SVProgressHUD.dismiss();
            });
          },
        );
      });
    }

    // 引导
    void _versionGuidance() {
      void _action() {
        _versionAlert = false;

        if (getPermission == true) {
          Get.find<PersonalDataController>().authorizationPermission(
            complete: complete,
          );
        }
      }

      StorageUtils.sharedPreferences.then((preferences) {
        bool? _versionGuidanceShow =
            preferences.getBool("kAppVersionGuidanceShow");
        if (_versionGuidanceShow == null || _versionGuidanceShow == false) {
          debugPrint("引导页");
          LaunchGuidance.show(context, () {
            preferences.setBool("kAppVersionGuidanceShow", true);
            _action();
          });
        } else {
          _action();
        }
      });
    }

    if (resume == false) {
      SVProgressHUD.show();
    }

    // 版本更新
    SystemApi.version(params: {}, isShowErr: false).then((value) {
      var data = value ?? {};
      String _version = "";
      if (kReleaseMode && GetPlatform.isAndroid) {
        _version = (data["android"] ?? {})["version"] ?? "";
        if (_version.length > 0) {
          if (_version != this.appVersion) {
            _alert();
          } else {
            _versionGuidance();
          }
        } else {
          _versionGuidance();
        }
      } else {
        _versionGuidance();
      }

      if (appState != AppCurrentState.init && accountModel.userId.length > 0) {
        // 定位
        String _location = data["location"] ?? "";
        if (_location.length > 0 && _location != accountModel.location) {
          updateAccountInfo(
            params: {"location": _location},
            editRequest: false,
          );
          this.accountModel.location = _location;
        }
      }

      Future.delayed(Duration(milliseconds: 100), () {
        SVProgressHUD.dismiss();
      });
    }).catchError((error) {
      SVProgressHUD.dismiss();
      _versionGuidance();
    });
  }

  /// 批量获取好友信息
  Future<List<FriendModel>> friendsItems(List ids) async {
    Completer<List<FriendModel>> _completer = Completer();
    if (ids.length == 0) {
      _completer.complete([]);
      return _completer.future;
    }

    // 批量获取好友信息
    AccountApi.friendsItems(params: {"ids": ids}, isShowErr: false)
        .then((value) async {
      List<FriendModel> _riskFriends = [];
      // 更新好友信息
      void _insertOrUpdateFriends(
          FriendModel element, void Function() finish) async {
        await accountDB!.query(
          kAppFriendTableName,
          where: "userId = '${element.userId}'",
          limit: 1,
          columns: ["timeoutDate", "timeout", "risk"],
        ).then((_list) async {
          if (_list.length == 1) {
            String _timeoutDate = "${_list.first['timeoutDate'] ?? ''}";
            if (element.timeout != _list.first["timeout"] ||
                _timeoutDate.length == 0) {
              element.timeoutDate = DateUtil.formatDate(DateTime.now(),
                  format: "yyyy-MM-dd HH:mm:ss");
            } else {
              element.timeoutDate = _timeoutDate;
            }

            if (element.risk != _list.first["risk"]) {
              _riskFriends.add(element);
            }

            // 更新用户信息
            await accountDB!.update(
              kAppFriendTableName,
              element.toJson(),
              where: "userId = '${element.userId}'",
            );

            finish();
          } else {
            if (element.timeout > 0) {
              element.timeoutDate = DateUtil.formatDate(DateTime.now(),
                  format: "yyyy-MM-dd HH:mm:ss");
            }

            // 插入新用户
            await accountDB!.insert(
              kAppFriendTableName,
              element.toJson(),
            );

            _riskFriends.add(element);

            finish();
          }
        });
      }

      // 处理危机用户
      void _handleRiskFriends(List<FriendModel> friends) async {
        // 创建危机聊天
        List<FriendModel> _riskList =
            friends.where((element) => element.risk == 1).toList();
        if (_riskList.length > 0) {
          List<ChatRecordModel> _list = [];
          void _riskRecord(FriendModel friend, void Function() finish) async {
            ChatRecordModel _model = ChatRecordModel.fromJson({});
            _model.fromId = friend.userId;
            _model.action = "risk_warn";
            _model.content = "当前用户可能非本人或异常，建议不进行通信！";
            _model.time = DateUtil.formatDate(DateTime.now(),
                format: "yyyy-MM-dd HH:mm:ss");
            _model.eventName = "chat";
            _model.isReaded = 0;
            _model.sendState = 1;
            _model.decrypt = 2;
            _model.eventId = "${DateTime.now().millisecondsSinceEpoch}";
            _list.add(_model);

            // 插入聊天消息
            await accountDB!.insert(
              kAppChatRecordTableName,
              _model.toJson(),
            );

            finish();
          }

          for (var i = 0; i < _riskList.length; i++) {
            FriendModel _riskFriend = _riskList[i];
            QueueUtil.get("friend_risk_create_${_riskFriend.userId}")
                ?.addTask(() {
              return _riskRecord(_riskFriend, () {
                if (i == _riskList.length - 1) {
                  chatHandler.add({StreamActionType.chat: _list});
                }
              });
            });
          }
        }
      }

      List _items = value["items"] ?? [];
      List<FriendModel> _friends = [];

      for (var i = 0; i < _items.length; i++) {
        var element = _items[i];
        (element ?? {})["risk"] = ((element ?? {})["risk"] == true ||
                (element ?? {})["risk"] == "true")
            ? 1
            : 0;
        FriendModel _model = FriendModel.fromJson(element ?? {});
        _model.updateState = 1;
        _friends.add(_model);

        QueueUtil.get("friend_${_model.userId}")?.addTask(() {
          return _insertOrUpdateFriends(_model, () {
            if (i == _items.length - 1) {
              QueueUtil.get("risk_friends")?.addTask(() {
                return _handleRiskFriends(_riskFriends);
              });

              try {
                Get.find<PersonalDataController>().launchMessageDestroy();
              } catch (e) {}

              _completer.complete(_friends);
            }
          });
        });
      }
    }).catchError((error) {
      _completer.complete([]);
    });

    return _completer.future;
  }

  /// 获取好友信息
  Future<FriendModel> friendsInfo({required String id}) async {
    Completer<FriendModel> _completer = Completer();
    AccountApi.friendsInfo(params: {"id": id}, isShowErr: false)
        .then((value) async {
      (value ?? {})["risk"] =
          ((value ?? {})["risk"] == true || (value ?? {})["risk"] == "true")
              ? 1
              : 0;
      FriendModel _friendModel = FriendModel.fromJson(value ?? {});
      _friendModel.userId = id;
      // 入库
      List _list = await this.accountDB!.query(
            kAppFriendTableName,
            where: "userId = '$id'",
            limit: 1,
          );

      if (_list.length == 1) {
        Map<String, Object> _params = {};
        if (_friendModel.avatar.length > 0) {
          _params["avatar"] = _friendModel.avatar;
        }
        if (_friendModel.key.length > 0) {
          _params["key"] = _friendModel.key;
        }

        if (_friendModel.nickname.length > 0) {
          _params["nickname"] = _friendModel.nickname;
        }

        if (_friendModel.remark.length > 0) {
          _params["remark"] = _friendModel.remark;
        }

        if (_friendModel.tags.length > 0) {
          _params["tags"] = _friendModel.tags;
        }

        await this.accountDB!.update(
              kAppFriendTableName,
              _params,
              where: "userId = '$id'",
            );
      } else {
        await this.accountDB!.insert(
              kAppFriendTableName,
              _friendModel.toJson(),
            );
      }

      _completer.complete(_friendModel);
    }).catchError((error) {
      _completer.complete(FriendModel.fromJson({}));
    });

    return _completer.future;
  }

  // 用户信息修改、更新
  void updateAccountInfo({
    required Map<String, Object> params,
    void Function()? finish,
    bool editRequest = true,
  }) {
    void _updateAction() async {
      Map<String, Object?> _values = {};
      if (params.containsKey("nickname")) {
        this.accountModel.nickname = "${params['nickname']}";
        _values["nickname"] = this.accountModel.nickname;
      } else if (params.containsKey("avatar")) {
        this.accountModel.avatar = "${params['avatar']}";
        _values["avatar"] = this.accountModel.avatar;
      } else if (params.containsKey("sex")) {
        this.accountModel.sex = "${params['sex']}";
        _values["sex"] = this.accountModel.sex;
      } else if (params.containsKey("emergency_phone")) {
        this.accountModel.emergencyPhone = "${params['emergency_phone']}";
        _values["emergencyPhone"] = this.accountModel.emergencyPhone;
      } else if (params.containsKey("xpin")) {
        this.accountModel.xpin = "${params['xpin']}";
        _values["xpin"] = this.accountModel.xpin;
      } else if (params.containsKey("location")) {
        this.accountModel.location = "${params['location']}";
        _values["location"] = this.accountModel.location;
      }

      this.update(["kUpdateAccountInfo"]);

      if (_values.length > 0) {
        await this.accountDB!.update(
              kAppAccountTableName,
              _values,
              where: "userId = '${this.accountModel.userId}'",
            );
      }

      Future.delayed(Duration(milliseconds: 300), () {
        if (editRequest) {
          SVProgressHUD.dismiss();
        }

        if (finish != null) {
          finish();
        }
      });
    }

    if (editRequest) {
      SVProgressHUD.show();
      AccountApi.editUserInfo(params: params).then((value) {
        _updateAction();
      }).catchError((error) {
        SVProgressHUD.dismiss();
      });
    } else {
      _updateAction();
    }
  }

  /// 批量获取好友信息（50位）
  void batchFriendsInfo(void Function() feedback) {
    int _pageSize = 50;
    List _ids = [];
    var _list = jsonDecode(this.accountModel.friends);
    List _friends = List.from(_list.runtimeType == String
        ? ("$_list".length == 0 ? [] : jsonDecode(_list))
        : _list);
    _ids = List.generate(_friends.length, (index) => index).map((index) {
      return _friends[index]["id"];
    }).toList();

    if (_ids.length == 0) {
      feedback();
      return;
    }

    debugPrint("好友id列表:$_ids");
    // 分页
    int _pageCount =
        _ids.length > _pageSize ? (_ids.length / _pageSize).ceil() : 1;
    debugPrint("批量获取好友信息:$_pageCount页");
    List _friendIdPage(int page) {
      var start = page * _pageSize;
      var end = _pageSize * (page + 1);
      if (end > _ids.length) {
        end = _ids.length;
      }

      debugPrint("分页 -- start:$start -- end:$end");
      List _list = _ids.sublist(
        start,
        end,
      );

      return _list;
    }

    for (var i = 0; i < _pageCount; i++) {
      QueueUtil.get("friend_page_$i")?.addTask(() {
        return friendsItems(_friendIdPage(i)).then((value) {
          if (i == _pageCount - 1) {
            debugPrint("批量获取好友信息完成");
            feedback();
          }
        });
      });
    }
  }

  /// 获取用户信息
  Future<void> accountInfo({required String userId}) async {
    Completer completer = Completer();

    void _requestAccountInfo(void Function(AccountModel? account)? finish) {
      AccountApi.userInfo(isShowErr: false).then((value) async {
        (value ?? {})["rescue"] = ((value ?? {})["rescue"] == true ||
                (value ?? {})["rescue"] == "true")
            ? 1
            : 0;
        (value ?? {})["real"] =
            ((value ?? {})["real"] == true || (value ?? {})["real"] == "true")
                ? 1
                : 0;
        (value ?? {})["risk"] =
            ((value ?? {})["risk"] == true || (value ?? {})["risk"] == "true")
                ? 1
                : 0;
        this.accountModel = AccountModel.fromJson(value ?? {});
        this.accountModel.userId = userId;

        if (finish != null) {
          finish(this.accountModel);
        }
      }).catchError((error) {
        debugPrint("获取用户信息失败:$error");
        if (finish != null) {
          finish(null);
        }
      });
    }

    _requestAccountInfo((account) async {
      if (account == null) {
        completer.completeError("logout");
      } else {
        List _list = await this.accountDB!.query(
          kAppAccountTableName,
          where: "userId = '$userId'",
          columns: ["userId"],
        );

        if (_list.length == 0) {
          await this
              .accountDB!
              .insert(kAppAccountTableName, this.accountModel.toJson());
          debugPrint("插入用户信息");
        } else {
          await this.accountDB!.update(
                kAppAccountTableName,
                this.accountModel.toJson(),
                where: "userId = '$userId'",
              );
          debugPrint("更新用户信息");
        }

        this.update(["kUpdateAccountInfo"]);
        completer.complete();
      }
    });

    return completer.future;
  }

  /// 前台服务注册
  Future<void> startService({required Map auth}) async {
    debugPrint("前台服务");
    return await ForegroundService().startTask(
      auth: auth,
    );
  }

  void stopService() {
    ForegroundService().stopTask();
  }

  /// 登录
  void cacheLogin({required Map auth}) {
    if (auth["token"] != null) {
      // 已登录
      kAppConfig.apiHeader["Authorization"] = "Bearer ${auth['token']}";
      this.appState = AppCurrentState.logined;

      StorageUtils.account(userId: auth["userId"]).then((value) {
        if (value == null) {
          // 数据库初始化失败
          logout();
          utilsToast(msg: "数据库初始化失败");
        } else {
          this.accountDB = value;
          accountInfo(userId: auth["userId"]).then((value) {
            void _init() {
              debugPrint("cacheLogin登录完成:${auth["userId"]}");
              kAppConfig.serverSalt = auth["salt"] ?? "";
              kAppConfig.curvePrivateKey = auth["curve25519"] ?? "";
              StorageUtils.readAssistantNickName();

              Get.offAllNamed(RouteNameString.home);
              // 未读消息数
              unreadCount();

              // 权限
              this.launchAert(
                Get.context!,
                complete: () async {
                  // 前台服务
                  await startService(auth: auth);
                  // 处理通知
                  disposeNotification();
                },
              );
            }

            QueueUtil.get("kCacheLoginInit")?.addTask(() {
              return _init();
            });
          }).catchError((error) {
            // 用户信息读取失败
            logout();
          });
        }
      }).catchError((error) {
        // 数据库初始化失败
        logout();
      });
    } else {
      logout();
    }
  }

  Future<void> login({
    required String token,
    required String salt,
    required String curve25519,
    required String userId,
    required bool newDevice, // 是否新设备登录
    required bool xpin,
  }) async {
    // 已登录
    kAppConfig.apiHeader["Authorization"] = "Bearer $token";
    this.appState = AppCurrentState.normal;
    kAppConfig.serverSalt = salt;
    kAppConfig.curvePrivateKey = curve25519;

    Future(
      () async {
        // 当前登录 存储 1 token 2 curve25519 3 服务器 salt 4 用户id
        await StorageUtils.setAuthStatus(
          token: token,
          curve25519: curve25519,
          salt: salt,
          userId: userId,
        );

        StorageUtils.account(userId: userId).then((value) {
          this.accountDB = value;

          accountInfo(userId: userId).then((value) {
            void _init() {
              debugPrint("login登录完成:$userId");

              QueueUtil.get("kBatchFrendsInfo")?.addTask(() {
                return batchFriendsInfo(() {
                  Get.offAllNamed(RouteNameString.home);
                  // 未读消息数
                  unreadCount();

                  // 权限
                  this.launchAert(
                    Get.context!,
                    complete: () async {
                      // 前台服务
                      await startService(auth: {
                        "token": token,
                        "salt": salt,
                        "curve25519": curve25519,
                        "userId": userId,
                      });

                      // 处理通知
                      disposeNotification();
                    },
                  );

                  if (xpin) {
                    StorageUtils.emptyCurrnetChatRecord();
                    this.xpinMode = xpin;
                  }

                  SVProgressHUD.dismiss();
                });
              });
            }

            QueueUtil.get("kNewLoginInit")?.addTask(() {
              return _init();
            });
          }).catchError((error) {
            // 用户信息读取失败
            SVProgressHUD.dismiss();
            logout();
          });
        }).catchError((error) {
          // 数据库初始化失败
          SVProgressHUD.dismiss();
          logout();
        });
      },
    );
  }

  /// 退出登录
  void logout() {
    if (appState != AppCurrentState.init) {
      StorageUtils.cleanAuthStatus();
      stopService();

      appState = AppCurrentState.init;

      if (badgeNumber.length > 0) {
        badgeNumber = "";
        update(["kBadgeNumber"]);
      }

      try {
        Get.find<PersonalDataController>().reportCancel();
        Get.find<PersonalDataController>().cancelMessageDestroy();
      } catch (e) {}

      StorageUtils.logout();
      SVProgressHUD.dismiss();
      Get.offAllNamed(RouteNameString.home);

      Future.delayed(Duration(seconds: 1), () {
        this.sseState = -1;
      });
    }
  }

  /// 注销用户
  void cancel() {
    if (appState != AppCurrentState.init) {
      StorageUtils.cleanAuthStatus();
      StorageUtils.emptyAccountDirectory();

      stopService();

      appState = AppCurrentState.init;
      try {
        Get.find<PersonalDataController>().reportCancel();
      } catch (e) {}

      StorageUtils.logout(remove: true);
      SVProgressHUD.dismiss();
      Get.offAllNamed(RouteNameString.home);

      Future.delayed(Duration(seconds: 1), () {
        this.sseState = -1;
      });
    }
  }

  /// 跳转拦截
  void onTabNotify(
      int jumpIndex, void Function(int index, bool xpin)? feedback) {
    void _jumpAction({bool xpin = false}) {
      if (jumpIndex == 2) {
        if (this.accountModel.level == 0) {
          if (xpin == false) {
            Get.to(
              TicketsPublishPage(),
              transition: Transition.downToUp,
              popGesture: false,
              fullscreenDialog: true,
            );
          }
        } else {
          try {
            Get.toNamed(RouteNameString.customer);
          } catch (e) {}
        }
      } else {
        if (feedback != null) {
          feedback(jumpIndex, xpin);
        }
      }
    }

    // 未登录
    if (this.appState == AppCurrentState.init) {
      debugPrint("未登录");
      Get.toNamed(RouteNameString.login);
      return;
    }
    // 未实名
    if (this.accountModel.real == 0) {
      debugPrint("未实名");
      Get.to(RealNameAuthPage(), popGesture: false);
      return;
    }
    // 验证PIN码
    if (this.appState == AppCurrentState.logined) {
      debugPrint("验证PIN码");
      PincodeInputPage.show(Get.context!, (xpin) {
        Future.delayed(Duration(milliseconds: 300), () {
          _jumpAction(xpin: xpin);
        });
      });
      return;
    }

    _jumpAction();
  }

  @override
  void onInit() async {
    Get.put(PersonalDataController());
    Get.put(TicketsDataController());

    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    if (chatHandler.isClosed == false) {
      chatHandler.close();
    }

    if (messageHandler.isClosed == false) {
      messageHandler.close();
    }

    super.onClose();
  }
}
