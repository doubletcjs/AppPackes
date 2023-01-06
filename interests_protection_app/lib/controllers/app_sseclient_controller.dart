import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/message_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/models/chat_record_model.dart';
import 'package:interests_protection_app/models/message_model.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/local_notification.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:objectid/objectid.dart';

class AppSseclientController {
  AppHomeController? _appHomeController;
  bool _clientConnected = false;
  bool _subscribeProgress = false;

  // 批量好友消息更新
  List _friendUpdateIdList = [];
  Timer? _friendUpdateTimer;
  List _friendAddIdList = [];
  Timer? _friendAddTimer;

  // 消息上报
  Timer? _reportTimer;

  // 解密消息
  void decryptMessage({
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

          await _appHomeController!.accountDB!.update(
            kAppChatRecordTableName,
            {"decrypt": 1},
            where: _where(model),
          );

          _completer.complete(model);
        }

        // 解密成功
        void _successful(ChatRecordModel model) async {
          model.decrypt = 2;

          await _appHomeController!.accountDB!.update(
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
            debugPrint("解密文件名");
            CryptoUtils.decrypFilename(
              base64Text: model.encryptSources,
              salt: _salt,
            ).then((filename) {
              if (filename.length == 0) {
                debugPrint("文件名解密失败");
                _recordUndecrypt(model);
              } else {
                model.filename = filename;
                _successful(model);
              }
            }).catchError((error) {
              debugPrint("文件名解密失败:$error");
              _recordUndecrypt(model);
            });
          } else {
            // 解密文本
            debugPrint("解密文本");
            CryptoUtils.decryptText(
              publicKey: model.publicKey,
              base64Text: model.encryptSources,
              salt: _salt,
            ).then((content) {
              debugPrint("解密文本");
              if (content.length == 0) {
                debugPrint("文本解密失败");
                _recordUndecrypt(model);
              } else {
                model.content = content;
                _successful(model);
              }
            }).catchError((error) {
              debugPrint("文本解密失败:$error");
              _recordUndecrypt(model);
            });
          }
        }).catchError((error) {
          debugPrint("salt解密失败:$error");
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
            if (customer) {
              _appHomeController!.chatHandler
                  .add({StreamActionType.customer: _decryptRecordList});
            } else {
              _appHomeController!.chatHandler
                  .add({StreamActionType.chat: _decryptRecordList});
            }

            debugPrint("解密队列完成");
          }
        });
      });
    }
  }

  // 消息处理
  Future<String> _processingMessage(
      {required String messageSign, required ChatRecordModel model}) async {
    Completer<String> _completer = Completer();
    // 聊天消息处理
    Future<void> _insertChatRecord({bool tempChat = false}) async {
      List<Map<String, Object?>> _list =
          await _appHomeController!.accountDB!.query(
        kAppChatRecordTableName,
        where: "eventId == '${model.eventId}' AND isMine = '0'",
        limit: 1,
      );

      if (_list.length == 1) {
        // 忽略数据变更, 目前不会有消息变更操作
        debugPrint("忽略数据变更，目前不会有消息变更操作");
        if (_completer.isCompleted == false) {
          _completer.complete(model.eventId);
        }
      }
      // 入库
      else {
        // 本地通知
        int _raw = 0;
        void _insertNotification() {
          var allowNotice =
              (Get.currentRoute == "/customer" || Get.currentRoute == "/chat")
                  ? false
                  : true;
          if (_raw > 0) {
            // 未读消息数
            _appHomeController?.unreadCount();

            if (allowNotice) {
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

              notification.mustSend("新消息", notificationContent,
                  notificationId: params['id'], params: json.encode(params));
            }

            if (tempChat == false) {
              debugPrint("聊天记录入库成功");
              _completer.complete(model.eventId);
            }
          } else {
            if (tempChat == false) {
              debugPrint("聊天记录入库失败");
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
          debugPrint("新开聊天会话");
          model.decrypt = 2;
        }

        _raw = await _appHomeController!.accountDB!.insert(
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
                decryptMessage(
                  customer: true,
                  recordList: [model],
                );
              } else {
                List _friendList = await _appHomeController!.accountDB!.query(
                  kAppFriendTableName,
                  where: "userId = '${model.fromId}' AND updateState = '1'",
                  columns: ["key"],
                  limit: 1,
                );

                if (_friendList.length > 0) {
                  // 使用旧key解密
                  model.publicKey = "${_friendList.first['key']}";
                  decryptMessage(
                    customer: false,
                    recordList: [model],
                  );
                } else {
                  // 好友key更新,暂缓解密消息
                  debugPrint("好友key更新,暂缓解密消息");
                }
              }
            }
          } else {
            if (model.eventName == "customer") {
              _appHomeController!.chatHandler
                  .add({StreamActionType.customer: model});
            } else {
              _appHomeController!.chatHandler
                  .add({StreamActionType.chat: model});
            }
          }
        }
      }
    }

    if (model.eventName == "system") {
      // 系统消息库
      List<Map<String, Object?>> _list =
          await _appHomeController!.accountDB!.query(
        kAppMessageTableName,
        where: "eventId == '${model.eventId}'",
        limit: 1,
      );

      int _raw = 0;
      if (_list.length == 1) {
        // 忽略数据变更, 目前不会有消息变更操作
        _raw = 1;
        debugPrint("忽略数据变更，目前不会有消息变更操作");
      } else {
        model.time = model.time
            .replaceAll("+08:00", "Z")
            .replaceAll("T", " ")
            .replaceAll("Z", "");
        if (model.action == "friend_update") {
          _raw = 1;
        } else {
          _raw = await _appHomeController!.accountDB!.insert(
            kAppMessageTableName,
            MessageModel.fromJson(model.toJson()).toJson(),
          );
        }
      }

      // 标记好友信息更新
      void _markFriendUpdate() async {
        await _appHomeController?.accountDB!.update(
          kAppFriendTableName,
          where: "userId = '${model.fromId}'",
          {"updateState": 0},
        );
      }

      // 系统消息入库
      void _systemComplete() {
        if (_raw > 0) {
          debugPrint("系统消息入库成功");
          _completer.complete(model.eventId);
        } else {
          debugPrint("系统消息入库失败");
          _completer.complete("");
        }
      }

      if (model.action == "rescue_end") {
        // 结束救援
        debugPrint("结束救援");
        _appHomeController!.messageHandler.add(
          {StreamActionType.system: SystemStreamActionType.rescueEnd},
        );

        _systemComplete();
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
            _appHomeController?.messageHandler.add({
              StreamActionType.system: _ids,
            });

            // 更新好友资料
            _appHomeController!.friendsItems(_ids).then((value) async {
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

                List _undecryptRecordList =
                    await _appHomeController!.accountDB!.query(
                  kAppChatRecordTableName,
                  where:
                      "eventName = 'chat' AND $_where AND decrypt = '0' AND isMine = '0'",
                );
                debugPrint("使用新key解密暂缓消息:${_undecryptRecordList.length}");

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
                      decryptMessage(
                        customer: false,
                        recordList: _recordList,
                      );
                    }
                  }
                }

                _appHomeController!.messageHandler.add({
                  StreamActionType.system: value,
                });
              }
            });

            _friendUpdateTimer?.cancel();
            _friendUpdateTimer = null;
            _friendUpdateIdList.clear();
          }
        }));
      } else if (model.action == "friend_delete") {
        // 对方删除好友
        debugPrint("对方删除好友");
        // 清空好友消息记录
        StorageUtils.cleanFriendChatRecord(model.fromId).then((fromId) async {
          // 标记好友删除
          await _appHomeController!.accountDB!.update(
            kAppFriendTableName,
            {"key": "delete"},
            where: "userId = '${model.fromId}'",
          );

          _appHomeController!.messageHandler.add({
            StreamActionType.friendDelete: model.fromId,
          });

          _systemComplete();

          // 更新好友列表
          var _list = jsonDecode(_appHomeController!.accountModel.friends);
          List _friends = List.from(_list.runtimeType == String
              ? ("$_list".length == 0 ? [] : jsonDecode(_list))
              : _list);
          _friends.removeWhere((element) => element["id"] == model.fromId);

          await _appHomeController!.accountDB!.update(
            kAppAccountTableName,
            {"friends": jsonEncode(_friends)},
            where: "userId = '${_appHomeController!.accountModel.userId}'",
          );

          _appHomeController!.accountModel.friends = jsonEncode(_friends);

          // 未读消息数
          _appHomeController?.unreadCount();
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
            var _list = jsonDecode(_appHomeController!.accountModel.friends);
            List _friends = List.from(_list.runtimeType == String
                ? ("$_list".length == 0 ? [] : jsonDecode(_list))
                : _list);

            _ids.forEach((element) {
              if (_friends.contains({"id": element}) == false) {
                _friends.add({"id": element});
              }
            });

            await _appHomeController!.accountDB!.update(
              kAppAccountTableName,
              {"friends": jsonEncode(_friends)},
              where: "userId = '${_appHomeController!.accountModel.userId}'",
            );

            _appHomeController!.accountModel.friends = jsonEncode(_friends);

            // 标记好友信息更新
            _appHomeController?.messageHandler.add({
              StreamActionType.system: _ids,
            });

            // 获取好友资料
            _appHomeController!.friendsItems(_ids).then((value) async {
              if (value.length > 0) {
                _appHomeController!.messageHandler.add(
                  {StreamActionType.system: SystemStreamActionType.friendAdd},
                );
              }

              String _where = "";
              for (var i = 0; i < _ids.length; i++) {
                String _element = _ids[i];
                if (_where.length == 0) {
                  _where = "fromId = '$_element'";
                } else {
                  _where += " OR fromId = '$_element'";
                }

                if (i == _ids.length - 1) {
                  var _tempChatList =
                      await _appHomeController!.accountDB!.query(
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
        _appHomeController!.friendsInfo(id: model.fromId).then((value) {
          if (value.userId.length > 0) {
            // 好友申请
            _appHomeController!.messageHandler.add({
              StreamActionType.system: MessageModel.fromJson(model.toJson())
            });
          }

          _systemComplete();

          // 未读消息数
          _appHomeController?.unreadCount();
        });
      } else if (model.action == "message_destroy") {
        // 删除消息
        if (model.content.length == 0) {
          debugPrint("清空好友消息记录");
          // 清空好友消息记录
          StorageUtils.cleanFriendChatRecord(
            model.fromId,
          ).then((fromId) {
            if (fromId.length > 0) {
              _appHomeController!.messageHandler.add(
                {
                  StreamActionType.messageDestroy: {"fromId": fromId}
                },
              );

              // 未读消息数
              _appHomeController?.unreadCount();
            }
          });
        } else {
          debugPrint("删除单条消息");
          // 删除单条消息 客服不会发删除消息通知
          StorageUtils.deleteMessage(
            false,
            model.fromId,
            model.content, // eventId
          ).then((eventId) {
            if (eventId.length > 0) {
              _appHomeController!.messageHandler.add(
                {
                  StreamActionType.messageDestroy: {
                    "fromId": model.fromId,
                    "eventId": eventId,
                  }
                },
              );

              // 未读消息数
              _appHomeController?.unreadCount();
            }
          });
        }

        _systemComplete();
      } else if (model.action == "customer_switch") {
        // 客服接入
        debugPrint("客服接入");
        MessageApi.customerInfo(isShowErr: false).then((value) async {
          String _nickname = (value ?? {})["nickname"] ?? "";
          if (kAppConfig.assistantNickName != _nickname &&
              _nickname.length > 0) {
            kAppConfig.assistantNickName = _nickname;
            StorageUtils.updateAssistantNickName();

            _appHomeController!.messageHandler.add({
              StreamActionType.system: SystemStreamActionType.customerSwitch
            });
          }
        });

        _systemComplete();
      } else if (model.action == "customer_end") {
        // 客服会话结束
        debugPrint("客服会话结束");
        _appHomeController!.messageHandler.add({
          StreamActionType.system: SystemStreamActionType.customerEnd,
        });
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

  // 重连
  void _reconnectAction() {
    void _action() {
      Future.delayed(Duration(seconds: 3), () {
        debugPrint("重连");
        subscribe();
      });
    }

    QueueUtil.get("kSseReconnectAction")?.addTask(() {
      return _action();
    });
  }

  // 退出登录，重置消息签名记录
  void restoreMessageSign() {
    StorageUtils.sharedPreferences.then((value) {
      value.remove("kMessageSignOld");
      value.remove("kLastEventId");
    });

    _appHomeController?.sseState = -1;

    _clientConnected = false;
    _subscribeProgress = false;

    SSEClient.unsubscribeFromSSE();
  }

  void subscribe() {
    if (_clientConnected || _subscribeProgress) {
      _appHomeController?.sseState = 1;
      return;
    }

    _subscribeProgress = true;

    if (_appHomeController == null) {
      _appHomeController = Get.find<AppHomeController>();
    }

    _appHomeController?.sseState = 0;

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
      debugPrint("header:$header");
      String sseUrl = "${kAppConfig.apiUrl}/message/pull";
      String reportId = "";

      SSEClient.subscribeToSSE(
        url: sseUrl,
        header: header,
      ).listen(
        (event) {
          if (_subscribeProgress) {
            void _action() {
              _subscribeProgress = false;
              _clientConnected = true;
              _appHomeController?.sseState = 1;
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

                debugPrint("eventName:${recordModel.eventName}");
                debugPrint("消息:${recordModel.toJson()}");
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
                            debugPrint("上报消息事件id");
                            // 上报消息事件id
                            MessageApi.report(
                              params: {
                                "data": reportId,
                                "type": "unread",
                              },
                              isShowErr: false,
                            ).then((value) {
                              debugPrint("上报消息最后事件id");
                            }).catchError((error) {
                              debugPrint("上报消息最后事件id失败");
                            });
                          }

                          QueueUtil.get("kReportEventId_${recordModel.eventId}")
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
            debugPrint("心跳");
          }

          StorageUtils.sharedPreferences.then((value) {
            value.setString("kMessageSignOld", messageSign);
          });
        },
        onDone: () {
          debugPrint("_sseMessageMonitor onDone");
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
        onError: (error) {
          if ("$error" != "Connection closed while receiving data") {
            debugPrint("_sseMessageMonitor onError:$error");
            if (error == 403 || error == 401) {
              _appHomeController?.sseState = 2;
              _appHomeController?.logout();
              Future.delayed(Duration(seconds: 2), () {
                utilsToast(msg: "SSE异常断开,错误码:$error,TOKEN过期?");
              });
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
}
