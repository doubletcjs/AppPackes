import 'dart:async';
import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/apis/message_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';

import 'package:interests_protection_app/models/account_model.dart';
import 'package:interests_protection_app/models/chat_record_model.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/models/message_model.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/local_notification.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:objectid/objectid.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class ServiceSseclientController {
  bool _clientConnected = false;
  bool _subscribeProgress = false;
  Database? _accountDB;
  AccountModel _accountModel = AccountModel.fromJson({});

  /// 状态
  int _state = -1; // -1 初始化 0 连接中 1 已连接 2 已断开
  int get state => _state;
  set state(int s) {
    if (s != _state) {
      _state = s;
    }

    FlutterForegroundTask.updateService(
      notificationTitle:
          "服务${_state == 0 ? '连接中' : _state == 1 ? '已连接' : _state == 2 ? '已断开' : '未连接'}",
    );
  }

  // 批量好友消息更新
  List _friendUpdateIdList = [];
  Timer? _friendUpdateTimer;
  List _friendAddIdList = [];
  Timer? _friendAddTimer;

  // 消息上报
  Timer? _reportTimer;

  // 定位上报
  Timer? _locationReportTimer;
  bool _sendingRescueInfo = false;

  /// 上报模式
  void _locationReportMode({required bool isRescue}) {
    _sendingRescueInfo = isRescue;

    _backgroundLocationReport();
  }

  /// 应用后台定时上报
  void _backgroundLocationReport() async {
    if (_locationReportTimer != null) {
      _locationReportTimer!.cancel();
      _locationReportTimer = null;
    }

    if ((await StorageUtils.sharedPreferences).getBool(kAppLocationStatus) ==
        true) {
      debugPrint("isolate ${_sendingRescueInfo ? 1 : 5}分钟定时上报");
      _locationReportTimer = Timer.periodic(
        // this.sendingRescueInfo
        //     ? Duration(seconds: 10)
        //     :
        Duration(minutes: _sendingRescueInfo ? 1 : 5),
        (timer) {
          if (_locationReportTimer != null) {
            if (_sendingRescueInfo) {
              _locationReportAction();
            } else {
              StorageUtils.sharedPreferences.then((value) {
                bool _status = value.getBool(kAppLocationStatus) ?? false;
                if (_status) {
                  _locationReportAction();
                }
              });
            }
          }
        },
      );
    } else {
      debugPrint("isolate 定位服务不可用");
    }
  }

  /// 上报定时关闭
  void _locationReportCancel() {
    if (_locationReportTimer != null) {
      debugPrint("isolate 上报定时关闭");
      _locationReportTimer!.cancel();
      _locationReportTimer = null;
    }
  }

  /// 上报位置
  void _locationReportAction() async {
    if ((await StorageUtils.sharedPreferences).getBool(kAppLocationStatus) ==
        true) {
      Geolocator.getLastKnownPosition(forceAndroidLocationManager: true);
      Geolocator.getCurrentPosition(
        desiredAccuracy: GetPlatform.isAndroid
            ? LocationAccuracy.high
            : LocationAccuracy.bestForNavigation,
        forceAndroidLocationManager: true,
        timeLimit: Duration(seconds: 5),
      ).then((_position) {
        String latitude = _position.latitude.toStringAsFixed(8);
        String longitude = _position.longitude.toStringAsFixed(8);

        if (longitude.length > 0 && latitude.length > 0) {
          debugPrint(
              "isolate 上报位置 longitude:${_position.longitude} latitude:${_position.latitude}");
          MessageApi.report(
            params: {
              "data": "${"${_position.longitude}"},${_position.latitude}",
              "type": "location",
            },
            isShowErr: false,
          ).then((value) {}).catchError((error) {});
        }
      }).catchError((error) {
        debugPrint("isolate getCurrentPosition error:$error");
      });
    }
  }

  /// 重连
  void _reconnectAction() {
    void _action() {
      Future.delayed(Duration(seconds: 3), () {
        debugPrint("isolate 重连");
        subscribe();
      });
    }

    QueueUtil.get("kSseReconnectAction")?.addTask(() {
      return _action();
    });
  }

  /// 取消订阅
  Future<void> unsubscribe() {
    Completer _completer = Completer();
    if (_clientConnected) {
      debugPrint("isolate 关闭SSE");
      StorageUtils.logout(isolate: true);
      _accountDB = null;

      this.state = -1;

      _clientConnected = false;
      _subscribeProgress = false;
      _locationReportCancel();

      SSEClient.unsubscribeFromSSE();
      _completer.complete();
    } else {
      _completer.complete();
    }

    return _completer.future;
  }

  /// 通知初始化
  void _initNotification() async {
    if ((await StorageUtils.sharedPreferences)
            .getBool(kAppNotificationStatus) ==
        true) {
      await notification.init();
      debugPrint("isolate 通知初始化");
    } else if ((await StorageUtils.sharedPreferences)
            .getBool(kAppNotificationStatus) ==
        false) {}
  }

  /// 订阅
  void subscribe({String? userId}) {
    if (_clientConnected || _subscribeProgress) {
      this.state = 1;

      return;
    }

    _subscribeProgress = true;
    this.state = 0;
    debugPrint("isolate 启动SSE");

    void _launch() {
      String messageSign = generateRandomString(12);
      String messageSignOld = "";
      String lastEventId = "";
      StorageUtils.sharedPreferences.then((preferences) {
        messageSignOld = preferences.getString("kMessageSignOld") ?? "";
        lastEventId = preferences.getString("kLastEventId") ?? "";

        String authorization = kAppConfig.apiHeader["Authorization"];
        String apiVersion = kAppConfig.apiHeader["Api-Version"];

        Map<String, String> header = {
          "Accept": "text/event-stream",
          "Cache-Control": "no-cache",
          "Connection": "keep-alive",
          "Authorization": "$authorization",
          "Api-Version": "$apiVersion",
          "Message-Sign-Old": "$messageSignOld",
          "Message-Sign-New": "$messageSign",
          "Last-Event-ID": "$lastEventId"
        };
        debugPrint("isolate header:$header");
        String sseUrl = "${kAppConfig.apiUrl}/message/pull";
        String reportId = "";

        SSEClient.subscribeToSSE(
          url: sseUrl,
          header: header,
        ).listen(
          (event) async {
            if (_subscribeProgress) {
              void _action() {
                _subscribeProgress = false;
                _clientConnected = true;
                this.state = 1;
              }

              QueueUtil.get("kSseclientSetState}")?.addTask(() {
                return _action();
              });
            }

            String eventId = event.id ?? "";
            if (eventId.length > 0 && eventId != "0") {
              try {
                Map<String, dynamic> _responseData =
                    json.decode(event.data ?? "");
                if (_responseData.length > 0) {
                  ChatRecordModel recordModel =
                      ChatRecordModel.fromJson(_responseData);
                  recordModel.eventId = eventId;
                  recordModel.eventName = event.event ?? "";

                  debugPrint("isolate eventName:${recordModel.eventName}");
                  debugPrint("isolate 消息:${recordModel.toJson()}");
                  QueueUtil.get("kProcessMessage_${recordModel.eventId}")
                      ?.addTask(() {
                    return _processingMessage(
                            messageSign: messageSign, model: recordModel)
                        .then((lastEventId) {
                      reportId = lastEventId;

                      if (_reportTimer != null) {
                        _reportTimer?.cancel();
                        _reportTimer = null;
                      }

                      _reportTimer =
                          Timer.periodic(Duration(seconds: 1), ((timer) async {
                        if (_reportTimer != null) {
                          if (reportId.length > 0) {
                            StorageUtils.sharedPreferences.then((value) {
                              value.setString("kLastEventId", reportId);
                            });

                            void _reportAction() {
                              debugPrint("isolate 上报消息事件id");
                              // 上报消息事件id
                              MessageApi.report(
                                params: {
                                  "data": reportId,
                                  "type": "unread",
                                },
                                isShowErr: false,
                              ).then((value) {
                                debugPrint("isolate 上报消息最后事件id");
                              }).catchError((error) {
                                debugPrint("isolate 上报消息最后事件id失败");
                              });
                            }

                            QueueUtil.get(
                                    "kReportEventId_${recordModel.eventId}")
                                ?.addTask(() {
                              return _reportAction();
                            });
                          }

                          _reportTimer?.cancel();
                          _reportTimer = null;
                        }
                      }));
                    });
                  });
                }
              } catch (e) {}
            } else {
              debugPrint("isolate 心跳");
            }

            StorageUtils.sharedPreferences.then((value) {
              value.setString("kMessageSignOld", messageSign);
            });
          },
          onDone: () {
            debugPrint("isolate _sseMessageMonitor onDone");
            // 可在这里进行重连。
            _subscribeProgress = false;
            if (_clientConnected) {
              _clientConnected = false;
              SSEClient.unsubscribeFromSSE();
            }

            _reconnectAction();
          },
          // 收到Error时触发,cancelOnError：遇到第一个Error时是否取消订阅，默认为false。
          // cancelOnError 为true时，出现onError时，onDone将不会回调
          onError: (error) async {
            if ("$error" != "Connection closed while receiving data") {
              debugPrint("isolate _sseMessageMonitor onError:$error");
              if (error == 403 || error == 401) {
                debugPrint("SSE异常断开,错误码:$error,TOKEN过期?");
                _state = 2;
              } else {
                _subscribeProgress = false;
                if (_clientConnected) {
                  _clientConnected = false;
                  SSEClient.unsubscribeFromSSE();
                }

                _reconnectAction();
              }
            }
          },
          cancelOnError: true,
        );
      });
    }

    if (userId != null) {
      StorageUtils.buildVersionCheck(() async {
        debugPrint("isolate 初始化数据库");
        _accountDB = await StorageUtils.account(userId: userId);

        debugPrint("isolate 当前登录用户");
        List _list = await _accountDB!.query(
          kAppAccountTableName,
          where: "userId = '$userId'",
          limit: 1,
        );
        _accountModel = AccountModel.fromJson(_list.first);

        _initNotification();

        _launch();

        if (_locationReportTimer == null) {
          // 上报定位
          if ((await StorageUtils.sharedPreferences)
                  .getBool(kAppLocationStatus) ==
              true) {
            _locationReportAction();
          }

          _locationReportMode(isRescue: _accountModel.rescue == 1);
        }
      });
    } else {
      _launch();
    }
  }

  /// 消息处理
  Future<String> _processingMessage(
      {required String messageSign, required ChatRecordModel model}) async {
    Completer<String> _completer = Completer();
    // 聊天消息处理
    Future<void> _insertChatRecord({bool tempChat = false}) async {
      List<Map<String, Object?>> _list = await _accountDB!.query(
        kAppChatRecordTableName,
        where: "eventId == '${model.eventId}' AND isMine = '0'",
        limit: 1,
      );

      if (_list.length == 1) {
        // 忽略数据变更, 目前不会有消息变更操作
        debugPrint("isolate 忽略数据变更，目前不会有消息变更操作");
        if (_completer.isCompleted == false) {
          _completer.complete(model.eventId);
        }
      }
      // 入库
      else {
        // 本地通知
        int _raw = 0;
        void _insertNotification() async {
          if (_raw > 0) {
            // 本地通知
            if ((await StorageUtils.sharedPreferences)
                    .getBool(kAppNotificationStatus) ==
                true) {
              Map params = {};
              params['event'] = model.eventName;
              params['id'] =
                  ObjectId.fromHexString(model.eventId).hashCode >> 32;
              var notificationContent = "";

              if (model.eventName == "customer") {
                notificationContent = "收到一条客服消息";
              } else {
                notificationContent = "收到一条好友消息";
                params['from'] = model.fromId;
              }

              debugPrint("isolate 后台推送");
              notification.mustSend(
                "新消息",
                notificationContent,
                notificationId: params['id'],
                params: json.encode(params),
              );
            }

            if (tempChat == false) {
              debugPrint("isolate 聊天记录入库成功");
              _completer.complete(model.eventId);
            }
          } else {
            if (tempChat == false) {
              debugPrint("isolate 聊天记录入库失败");
              _completer.complete("");
            }
          }
        }

        // 日期转换
        model.time = model.time
            .replaceAll("+08:00", "Z")
            .replaceAll("T", " ")
            .replaceAll("Z", "");

        // 记录加密源
        if (model.action == "file") {
          model.encryptSources = model.filename;
        } else {
          model.encryptSources = model.content;
        }

        if (tempChat == true) {
          debugPrint("isolate 新开聊天会话");
          model.decrypt = 2;
        }

        _raw = await _accountDB!.insert(
          kAppChatRecordTableName,
          model.toJson(),
        );

        _insertNotification();

        if (_raw > 0) {
          // 解密信息 lose 过期信息不解密 新开聊天会话不解密
          if (tempChat == false) {
            if (model.action != "lose") {
              if (model.eventName == "customer") {
                model.publicKey = kAppConfig.assistantCurvePublicKey;
                _decryptMessage(
                  customer: true,
                  recordList: [model],
                );
              } else {
                List _friendList = await _accountDB!.query(
                  kAppFriendTableName,
                  where: "userId = '${model.fromId}' AND updateState = '1'",
                  columns: ["key"],
                  limit: 1,
                );

                if (_friendList.length > 0) {
                  // 使用旧key解密
                  model.publicKey = "${_friendList.first['key']}";
                  _decryptMessage(
                    customer: false,
                    recordList: [model],
                  );
                } else {
                  // 好友key更新,暂缓解密消息
                  debugPrint("isolate 好友key更新,暂缓解密消息");
                }
              }
            }
          }
        }
      }
    }

    if (model.eventName == "system") {
      // 系统消息库
      List<Map<String, Object?>> _list = await _accountDB!.query(
        kAppMessageTableName,
        where: "eventId == '${model.eventId}'",
        limit: 1,
      );

      int _raw = 0;
      if (_list.length == 1) {
        // 忽略数据变更, 目前不会有消息变更操作
        _raw = 1;
        debugPrint("isolate 忽略数据变更，目前不会有消息变更操作");
      } else {
        model.time = model.time
            .replaceAll("+08:00", "Z")
            .replaceAll("T", " ")
            .replaceAll("Z", "");
        if (model.action == "friend_update") {
          _raw = 1;
        } else {
          _raw = await _accountDB!.insert(
            kAppMessageTableName,
            MessageModel.fromJson(model.toJson()).toJson(),
          );
        }
      }

      // 标记好友信息更新
      void _markFriendUpdate() async {
        await _accountDB!.update(
          kAppFriendTableName,
          where: "userId = '${model.fromId}'",
          {"updateState": 0},
        );
      }

      // 系统消息入库
      void _systemComplete() {
        if (_raw > 0) {
          debugPrint("isolate 系统消息入库成功");
          _completer.complete(model.eventId);
        } else {
          debugPrint("isolate 系统消息入库失败");
          _completer.complete("");
        }
      }

      if (model.action == "rescue_end") {
        // 结束救援
        debugPrint("isolate 结束救援");
        _systemComplete();
        _locationReportMode(isRescue: false);
      } else if (model.action == "friend_update") {
        if (_friendUpdateTimer != null) {
          _friendUpdateTimer?.cancel();
          _friendUpdateTimer = null;
        }

        if (_friendUpdateIdList.contains(model.fromId) == false) {
          _friendUpdateIdList.add(model.fromId);
        }

        _markFriendUpdate();
        _systemComplete();

        _friendUpdateTimer = Timer.periodic(Duration(seconds: 1), ((timer) {
          if (_friendUpdateTimer != null) {
            // 标记好友信息更新
            List<String> _ids = List<String>.from(_friendUpdateIdList);
            // 更新好友资料
            _friendsItems(_ids).then((value) async {
              if (value.length > 0) {
                // 使用新key解密暂缓消息
                String _where = "";
                value.forEach((element) {
                  if (_where.length == 0) {
                    _where = "fromId = '${element.userId}'";
                  } else {
                    _where = _where + " OR fromId = '${element.userId}'";
                  }
                });

                List _undecryptRecordList = await _accountDB!.query(
                  kAppChatRecordTableName,
                  where:
                      "eventName = 'chat' AND $_where AND decrypt = '0' AND isMine = '0'",
                );
                debugPrint(
                    "isolate 使用新key解密暂缓消息:${_undecryptRecordList.length}");

                List<ChatRecordModel> _recordList = [];
                for (var i = 0; i < _undecryptRecordList.length; i++) {
                  if ((_undecryptRecordList[i] ?? {}).length > 0) {
                    ChatRecordModel _model =
                        ChatRecordModel.fromJson(_undecryptRecordList[i] ?? {});
                    _model.publicKey = value
                        .firstWhere(
                            (element) => element.userId == _model.fromId)
                        .key;
                    _recordList.add(_model);
                  }

                  if (i == _undecryptRecordList.length - 1) {
                    if (_recordList.length > 0) {
                      _decryptMessage(
                        customer: false,
                        recordList: _recordList,
                      );
                    }
                  }
                }
              }
            });

            _friendUpdateTimer?.cancel();
            _friendUpdateTimer = null;
            _friendUpdateIdList.clear();
          }
        }));
      } else if (model.action == "friend_delete") {
        // 对方删除好友
        debugPrint("isolate 对方删除好友");
        // 清空好友消息记录
        StorageUtils.cleanFriendChatRecord(model.fromId).then((fromId) async {
          // 标记好友删除
          await _accountDB!.update(
            kAppFriendTableName,
            {"key": "delete"},
            where: "userId = '${model.fromId}'",
          );

          _systemComplete();

          // 更新好友列表
          var _list = jsonDecode(_accountModel.friends);
          List _friends = List.from(_list.runtimeType == String
              ? ("$_list".length == 0 ? [] : jsonDecode(_list))
              : _list);
          _friends.removeWhere((element) => element["id"] == model.fromId);

          await _accountDB!.update(
            kAppAccountTableName,
            {"friends": jsonEncode(_friends)},
            where: "userId = '${_accountModel.userId}'",
          );
        });
      } else if (model.action == "friend_add") {
        // 对方同意、添加好友
        if (_friendAddTimer != null) {
          _friendAddTimer?.cancel();
          _friendAddTimer = null;
        }

        if (_friendAddIdList.contains(model.fromId) == false) {
          _friendAddIdList.add(model.fromId);
        }

        _markFriendUpdate();
        _systemComplete();

        _friendAddTimer = Timer.periodic(Duration(seconds: 1), ((timer) async {
          if (_friendAddTimer != null) {
            List<String> _ids = List<String>.from(_friendAddIdList);
            _friendAddTimer?.cancel();
            _friendAddTimer = null;
            _friendAddIdList.clear();

            // 好友列表添加好友
            var _list = jsonDecode(_accountModel.friends);
            List _friends = List.from(_list.runtimeType == String
                ? ("$_list".length == 0 ? [] : jsonDecode(_list))
                : _list);

            _ids.forEach((element) {
              if (_friends.contains({"id": element}) == false) {
                _friends.add({"id": element});
              }
            });

            await _accountDB!.update(
              kAppAccountTableName,
              {"friends": jsonEncode(_friends)},
              where: "userId = '${_accountModel.userId}'",
            );

            // 获取好友资料
            _friendsItems(_ids).then((value) async {
              String _where = "";
              for (var i = 0; i < _ids.length; i++) {
                String _element = _ids[i];
                if (_where.length == 0) {
                  _where = "fromId = '$_element'";
                } else {
                  _where += " OR fromId = '$_element'";
                }

                if (i == _ids.length - 1) {
                  var _tempChatList = await _accountDB!.query(
                    kAppChatRecordTableName,
                    where:
                        "$_where AND eventName = 'chat' AND action = 'friend_add'",
                  );

                  if (_tempChatList.length == 0) {
                    // 入聊天库
                    model.eventName = "chat";
                    await _insertChatRecord(tempChat: true);
                  }
                }
              }
            });
          }
        }));
      } else if (model.action == "friend_apply") {
        // 获取好友基本资料
        _friendsInfo(id: model.fromId).then((value) {
          _systemComplete();
        });
      } else if (model.action == "message_destroy") {
        // 删除消息
        if (model.content.length == 0) {
          debugPrint("isolate 清空好友消息记录");
          // 清空好友消息记录
          StorageUtils.cleanFriendChatRecord(
            model.fromId,
          ).then((fromId) {});
        } else {
          debugPrint("isolate 删除单条消息");
          // 删除单条消息 客服不会发删除消息通知
          StorageUtils.deleteMessage(
            false,
            model.fromId,
            model.content, // eventId
          ).then((eventId) {});
        }

        _systemComplete();
      } else if (model.action == "customer_switch") {
        // 客服接入
        debugPrint("isolate 客服接入");
        MessageApi.customerInfo(isShowErr: false).then((value) async {
          String _nickname = (value ?? {})["nickname"] ?? "";
          if (kAppConfig.assistantNickName != _nickname &&
              _nickname.length > 0) {
            kAppConfig.assistantNickName = _nickname;
            StorageUtils.updateAssistantNickName();
          }
        });

        _systemComplete();
      } else if (model.action == "customer_end") {
        // 客服会话结束
        debugPrint("isolate 客服会话结束");
        _systemComplete();
      } else {
        _systemComplete();
      }
    } else {
      // 聊天记录库
      _insertChatRecord();
    }

    return _completer.future;
  }

  /// 解密消息
  void _decryptMessage({
    required bool customer,
    required List<ChatRecordModel> recordList,
  }) {
    String _where(ChatRecordModel model) {
      return customer
          ? "eventName = 'customer' AND eventId = '${model.eventId}' AND isMine = '0'"
          : "eventName = 'chat' AND fromId = '${model.fromId}' AND eventId = '${model.eventId}' AND isMine = '0'";
    }

    Future<ChatRecordModel> _decryptyAction(ChatRecordModel model) {
      Completer<ChatRecordModel> _completer = Completer();

      if (model.publicKey.length == 0) {
        model.decrypt = 1;
        _completer.complete(model);
      } else {
        // 记录未解密消息
        void _recordUndecrypt(ChatRecordModel model) async {
          model.decrypt = 1;

          await _accountDB!.update(
            kAppChatRecordTableName,
            {"decrypt": 1},
            where: _where(model),
          );

          _completer.complete(model);
        }

        // 解密成功
        void _successful(ChatRecordModel model) async {
          model.decrypt = 2;

          await _accountDB!.update(
            kAppChatRecordTableName,
            model.action == "file"
                ? {"filename": model.filename, "decrypt": 2}
                : {"content": model.content, "decrypt": 2},
            where: _where(model),
          );

          _completer.complete(model);
        }

        CryptoUtils.decryptSalt(base64Salt: model.salt).then((_salt) {
          if (model.action == "file") {
            // 解密文件名
            debugPrint("isolate 解密文件名");
            CryptoUtils.decrypFilename(
              base64Text: model.encryptSources,
              salt: _salt,
            ).then((filename) {
              if (filename.length == 0) {
                debugPrint("isolate 文件名解密失败");
                _recordUndecrypt(model);
              } else {
                model.filename = filename;
                _successful(model);
              }
            }).catchError((error) {
              debugPrint("isolate 文件名解密失败:$error");
              _recordUndecrypt(model);
            });
          } else {
            // 解密文本
            debugPrint("isolate 解密文本");
            CryptoUtils.decryptText(
              publicKey: model.publicKey,
              base64Text: model.encryptSources,
              salt: _salt,
            ).then((content) {
              debugPrint("isolate 解密文本");
              if (content.length == 0) {
                debugPrint("isolate 文本解密失败");
                _recordUndecrypt(model);
              } else {
                model.content = content;
                _successful(model);
              }
            }).catchError((error) {
              debugPrint("isolate 文本解密失败:$error");
              _recordUndecrypt(model);
            });
          }
        }).catchError((error) {
          debugPrint("isolate salt解密失败:$error");
          _recordUndecrypt(model);
        });
      }

      return _completer.future;
    }

    List<ChatRecordModel> _decryptRecordList = [];
    for (var i = 0; i < recordList.length; i++) {
      ChatRecordModel element = recordList[i];
      QueueUtil.get("kDecryptMessage_${element.eventId}")?.addTask(() async {
        return await _decryptyAction(element).then((value) {
          _decryptRecordList.add(value);
          if (_decryptRecordList.length == recordList.length) {
            debugPrint("isolate 解密队列完成");
          }
        });
      });
    }
  }

  /// 批量获取好友信息
  Future<List<FriendModel>> _friendsItems(List ids) async {
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
        await _accountDB!.query(
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
            await _accountDB!.update(
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
            await _accountDB!.insert(
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
            await _accountDB!.insert(
              kAppChatRecordTableName,
              _model.toJson(),
            );

            finish();
          }

          for (var i = 0; i < _riskList.length; i++) {
            FriendModel _riskFriend = _riskList[i];
            QueueUtil.get("friend_risk_create_${_riskFriend.userId}")
                ?.addTask(() {
              return _riskRecord(_riskFriend, () {});
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
  Future<FriendModel> _friendsInfo({required String id}) async {
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
      List _list = await _accountDB!.query(
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

        await _accountDB!.update(
          kAppFriendTableName,
          _params,
          where: "userId = '$id'",
        );
      } else {
        await _accountDB!.insert(
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
}
