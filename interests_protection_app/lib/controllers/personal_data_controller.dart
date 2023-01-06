import 'dart:async';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide ServiceStatus;
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/message_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/utils/local_notification.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:notification_permissions/notification_permissions.dart' as np;
import 'package:permission_handler/permission_handler.dart';

class PersonalDataController extends GetxController {
  List<bool> statusList = [false, false, false];
  Timer? rescueTimer;
  int rescueCountSecond = 8;
  bool sendingRescueInfo = false;

  // 系统消息监听器
  late StreamSubscription? _systemStreamSubscription;
  StreamController<List<bool>> stateHandler = StreamController.broadcast();

  Timer? _locationReportTimer;
  Timer? _destroyTimer;
  Position? localPosition;

  // 上报模式
  void setReportMode({required bool isRescue}) {
    this.sendingRescueInfo = isRescue;
    this.update();

    _forgroundReport();
  }

  // 上报位置
  void reportLocation({void Function()? feedBack, bool skipReport = false}) {
    if (this.statusList[0] == true) {
      Geolocator.getLastKnownPosition(forceAndroidLocationManager: true);
      Geolocator.getCurrentPosition(
        desiredAccuracy: GetPlatform.isAndroid
            ? LocationAccuracy.high
            : LocationAccuracy.bestForNavigation,
        forceAndroidLocationManager: true,
        timeLimit: Duration(seconds: 5),
      ).then((_position) {
        localPosition = _position;

        String latitude = _position.latitude.toStringAsFixed(8);
        String longitude = _position.longitude.toStringAsFixed(8);

        if (skipReport == false) {
          if (longitude.length > 0 && latitude.length > 0) {
            debugPrint(
                "上报位置 longitude:${_position.longitude} latitude:${_position.latitude}");
            MessageApi.report(
              params: {
                "data": "${"${_position.longitude}"},${_position.latitude}",
                "type": "location",
              },
              isShowErr: false,
            ).then((value) {}).catchError((error) {});
          }
        } else {
          debugPrint(
              "当前位置 longitude:${_position.longitude} latitude:${_position.latitude}");
        }

        if (feedBack != null) {
          feedBack();
        }
      }).catchError((error) {
        debugPrint("getCurrentPosition error:$error");
        if (feedBack != null) {
          feedBack();
        }
      });
    } else {
      if (feedBack != null) {
        feedBack();
      }
    }
  }

  // 上报定时关闭
  void reportCancel() {
    if (_locationReportTimer != null) {
      debugPrint("上报定时关闭");
      _locationReportTimer!.cancel();
      _locationReportTimer = null;
    }
  }

  // 应用前台定时上报
  void _forgroundReport() {
    if (_locationReportTimer != null) {
      _locationReportTimer!.cancel();
      _locationReportTimer = null;
    }

    if (this.statusList[0] == true) {
      debugPrint("${this.sendingRescueInfo ? 1 : 5}分钟定时上报");
      _locationReportTimer = Timer.periodic(
        // this.sendingRescueInfo
        //     ? Duration(seconds: 10)
        //     :
        Duration(minutes: this.sendingRescueInfo ? 1 : 5),
        (timer) {
          if (_locationReportTimer != null) {
            if (this.sendingRescueInfo) {
              reportLocation();
            } else {
              StorageUtils.sharedPreferences.then((value) {
                bool _status = value.getBool(kAppLocationStatus) ?? false;
                if (_status) {
                  reportLocation();
                }
              });
            }
          }
        },
      );
    } else {
      debugPrint("定位服务不可用");
    }
  }

  // 读取系统权限
  bool _requestingPermission = false;
  void authorizationPermission({void Function()? complete}) {
    if (_requestingPermission == false) {
      void _setPermissionState(bool state, int index) {
        this.statusList[index] = state;
        if (index == 0 && state == false) {
          reportCancel();
        }
      }

      // 通知
      Future<void> _notificationAction() async {
        Completer _completer = Completer();
        // 通知权限
        bool? _notificationStatus = (await StorageUtils.sharedPreferences)
            .getBool(kAppNotificationStatus);
        if (_notificationStatus == null) {
          if (await Permission.notification.status == PermissionStatus.denied ||
              await Permission.notification.status ==
                  PermissionStatus.permanentlyDenied) {
            // 未开启通知
            debugPrint("去开启通知");
            _requestingPermission = true;
            await np.NotificationPermissions.requestNotificationPermissions()
                .then((value) async {
              debugPrint("通知权限:$value");
              if (value == np.PermissionStatus.denied) {
                // 通知不可用
                debugPrint("通知服务不可用");
                _setPermissionState(false, 2);
              } else {
                // 通知授权成功
                _setPermissionState(true, 2);
                (await StorageUtils.sharedPreferences)
                    .setBool(kAppNotificationStatus, true);
              }
              _completer.complete();
            }).catchError((error) async {
              // 错误处理
              _setPermissionState(false, 2);
              _completer.complete();
            });
          } else {
            debugPrint("通知权限:${await Permission.notification.status}");
            // 通知已授权
            _setPermissionState(true, 2);
            (await StorageUtils.sharedPreferences)
                .setBool(kAppNotificationStatus, true);
            _completer.complete();
          }
        } else {
          // 二次确认
          if (await Permission.notification.status == PermissionStatus.denied ||
              await Permission.notification.status ==
                  PermissionStatus.permanentlyDenied) {
            // 通知不可用
            debugPrint("通知服务不可用");
            _setPermissionState(false, 2);
          } else {
            // 通知授权记录
            _setPermissionState(_notificationStatus, 2);
          }

          _completer.complete();
        }
      }

      // 定位
      Future<void> _locationAction() async {
        Completer _completer = Completer();
        if (await Permission.location.serviceStatus == ServiceStatus.disabled) {
          // 定位不可用
          debugPrint("定位服务不可用");
          _setPermissionState(false, 0);
          _completer.complete();
        } else {
          // 定位权限
          bool? _locationStatus = (await StorageUtils.sharedPreferences)
              .getBool(kAppLocationStatus);
          if (_locationStatus == null) {
            if (await Permission.location.status == PermissionStatus.denied ||
                await Permission.location.status ==
                    PermissionStatus.permanentlyDenied) {
              // 未开启定位
              debugPrint("去开启定位");
              _requestingPermission = true;
              await Permission.location.request().then((value) async {
                debugPrint("定位权限:$value");
                if (value == PermissionStatus.denied ||
                    value == PermissionStatus.permanentlyDenied) {
                  // 定位不可用
                  debugPrint("定位服务不可用");
                  _setPermissionState(false, 0);
                } else {
                  // 定位授权成功
                  _setPermissionState(true, 0);
                  (await StorageUtils.sharedPreferences)
                      .setBool(kAppLocationStatus, true);
                }
                _completer.complete();
              }).catchError((error) async {
                // 错误处理
                _setPermissionState(false, 0);
                _completer.complete();
              });
            } else {
              debugPrint("定位权限:${await Permission.location.status}");
              // 定位已授权
              _setPermissionState(true, 0);
              (await StorageUtils.sharedPreferences)
                  .setBool(kAppLocationStatus, true);
              _completer.complete();
            }
          } else {
            // 二次确认
            if (await Permission.location.status == PermissionStatus.denied ||
                await Permission.location.status ==
                    PermissionStatus.permanentlyDenied) {
              // 定位不可用
              debugPrint("定位服务不可用");
              _setPermissionState(false, 0);
            } else {
              // 定位授权记录
              _setPermissionState(_locationStatus, 0);
            }

            _completer.complete();
          }
        }
      }

      _locationAction().then((_) {
        _requestingPermission = false;
        _notificationAction().then((_) async {
          _requestingPermission = false;
          this.update();
          debugPrint("statusList:$statusList");

          if (statusList[2] == true) {
            await notification.init();
            await notification.registerApns();
          } else if (statusList[2] == false) {
            await notification.unregisterApns();
          }

          AppHomeController _controller = Get.find<AppHomeController>();
          if (_controller.appState != AppCurrentState.init &&
              _locationReportTimer == null) {
            // 上报定位
            if (statusList[0]) {
              reportLocation();
            }

            this.setReportMode(isRescue: _controller.accountModel.rescue == 1);
          }

          if (complete != null) {
            complete();
          }
        });
      });
    }
  }

  // 应用前台阅后即焚
  void cancelMessageDestroy() {
    debugPrint("关闭阅后即焚计时器");
    if (_destroyTimer != null) {
      _destroyTimer?.cancel();
      _destroyTimer = null;
    }
  }

  void launchMessageDestroy() {
    // 关闭旧计时器
    debugPrint("关闭旧计时器");
    if (_destroyTimer != null) {
      _destroyTimer?.cancel();
      _destroyTimer = null;
    }

    AppHomeController _controller = Get.find<AppHomeController>();
    if (_controller.appState != AppCurrentState.init) {
      _controller.accountDB!.query(
        kAppFriendTableName,
        where: "timeout > 0",
        columns: ["timeout", "userId", "timeoutDate"],
      ).then((list) {
        List<FriendModel> _records = [];
        list.forEach((element) {
          debugPrint("timeoutDate:${element["timeoutDate"]}");

          FriendModel _model = FriendModel.fromJson(element);
          _model.timeoutDate = "${element["timeoutDate"] ?? ""}";
          _records.add(_model);
        });

        if (_records.length > 0) {
          debugPrint("开启阅后即焚计时器");
          _forgroundDestroy(_records);
          _destroyTimer = Timer.periodic(Duration(seconds: 15), (timer) {
            _forgroundDestroy(_records);
          });
        } else {
          debugPrint("关闭阅后即焚计时器");
        }
      });
    }
  }

  void _forgroundDestroy(List<FriendModel> records) {
    if (records.length > 0) {
      String _chatWhere = "";
      String _now =
          DateUtil.formatDate(DateTime.now(), format: "yyyy-MM-dd HH:mm:ss");
      records.forEach((element) {
        if (element.timeout > 0) {
          String _dateWhere =
              "((julianday('$_now')-julianday(time))*24*60*60 >= ${element.timeout - 1})";

          if (_chatWhere.length == 0) {
            _chatWhere =
                "(fromId = '${element.userId}' AND time > '${element.timeoutDate}' AND $_dateWhere)";
          } else {
            _chatWhere = _chatWhere +
                " OR (fromId = '${element.userId}' AND time > '${element.timeoutDate}' AND $_dateWhere)";
          }
        }
      });

      if (_chatWhere.length > 0) {
        String _where = "eventName = 'chat' AND $_chatWhere";
        AppHomeController _controller = Get.find<AppHomeController>();
        _controller.accountDB!.query(
          kAppChatRecordTableName,
          where: _where,
          columns: ["fromId", "eventId"],
        ).then((list) async {
          if (list.length > 0) {
            list.removeWhere((element) =>
                element["isMine"] == 1 && element["sendState"] == 2);
            debugPrint("_where:$_where");
            debugPrint("阅后即焚数目:${list.length}");
            List _destroyList = [];
            for (var i = 0; i < list.length; i++) {
              var chat = list[i];
              await StorageUtils.deleteMessage(
                false,
                "${chat['fromId']}",
                "${chat['eventId']}",
              );

              _destroyList.add({
                "fromId": "${chat['fromId']}",
                "eventId": "${chat['eventId']}",
              });

              if (i == list.length - 1) {
                _controller.messageHandler.add({
                  StreamActionType.messageDestroy: _destroyList,
                });
              }
            }
          }
        });
      }
    }
  }

  @override
  void onInit() {
    _systemStreamSubscription = null;
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();

    // 系统消息监听
    _systemStreamSubscription =
        Get.find<AppHomeController>().messageHandler.stream.listen((event) {
      if (event.containsKey(StreamActionType.system)) {
        var _object = event[StreamActionType.system]!;
        if (_object == SystemStreamActionType.rescueEnd) {
          debugPrint("结束救援");

          this.rescueCountSecond = 8;
          if (this.rescueTimer != null) {
            this.rescueTimer?.cancel();
            this.rescueTimer = null;
          }

          this.setReportMode(isRescue: false);

          Future.delayed(Duration(milliseconds: 300), () {
            utilsToast(
              msg: "结束救援",
              milliseconds: 5000,
            );
          });
        }
      }
    });
  }

  @override
  void onClose() {
    if (_systemStreamSubscription != null) {
      _systemStreamSubscription?.cancel();
      _systemStreamSubscription = null;
    }

    if (stateHandler.isClosed == false) {
      stateHandler.close();
    }

    if (this.rescueTimer != null) {
      this.rescueTimer?.cancel();
      this.rescueTimer = null;
    }

    if (_destroyTimer != null) {
      _destroyTimer?.cancel();
      _destroyTimer = null;
    }

    super.onClose();
  }
}
