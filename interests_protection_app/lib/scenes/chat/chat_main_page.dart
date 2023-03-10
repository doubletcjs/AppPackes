import 'dart:async';
import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/message_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/controllers/app_message_controller.dart';
import 'package:interests_protection_app/models/chat_record_model.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/models/message_model.dart';
import 'package:interests_protection_app/scenes/chat/chat_setting_page.dart';
import 'package:interests_protection_app/scenes/chat/widgets/customer_header_bar.dart';
import 'package:interests_protection_app/scenes/chat/widgets/chat_input_widget.dart';
import 'package:interests_protection_app/scenes/chat/widgets/chat_item_widget.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';
import 'package:interests_protection_app/utils/widgets/file_preview_page.dart';
import 'package:interests_protection_app/utils/widgets/image_picker.dart';
import 'package:interests_protection_app/utils/widgets/photo_view_gallery.dart';
import 'package:path_provider/path_provider.dart';

class ChatMainPage extends StatefulWidget {
  final String? fromId;
  final bool? fromAlert;
  ChatMainPage({
    Key? key,
    this.fromId,
    this.fromAlert,
  }) : super(key: key);

  @override
  State<ChatMainPage> createState() => _ChatMainPageState();
}

class _ChatMainPageState extends State<ChatMainPage> {
  ScrollController _scrollController = ScrollController();
  AppHomeController _appHomeController = Get.find<AppHomeController>();
  ChatInputController _inputController = ChatInputController();
  bool _customer = false;
  String _curvePublicKey = kAppConfig.assistantCurvePublicKey;
  FriendModel _chatFriendModel = FriendModel.fromJson({});

  List<ChatRecordModel> _dataList = [];
  // ???????????????
  late StreamSubscription? _messageSubscription;
  // ?????????????????????
  late StreamSubscription? _systemSubscription;
  // ?????????????????????
  String _chatRootPath = "";

  // ??????????????????
  ChatRecordModel _fileSendingMessage(String filePath) {
    var date = DateTime.now();
    String filename = filePath.split("/").last;
    String localPath = _chatRootPath + "/upload/$filename";
    if (File(localPath).existsSync() == false) {
      File(filePath).copySync(localPath);
    } else {
      localPath = _chatRootPath +
          "/upload/${DateTime.now().millisecondsSinceEpoch}_$filename";
      File(filePath).copySync(localPath);
    }

    // ?????????????????????
    try {
      if (filename.toLowerCase().contains(".jpg") ||
          filename.toLowerCase().contains(".png") ||
          filename.toLowerCase().contains(".jpeg") ||
          filename.toLowerCase().contains(".gif")) {
        File(filePath).deleteSync();
      }
    } catch (e) {}

    ChatRecordModel _model = ChatRecordModel.fromJson({});
    _model.isMine = 1;
    _model.action = "file";
    _model.eventName = _customer ? "customer" : "chat";
    if (_customer == false) {
      _model.fromId = _chatFriendModel.userId;
    }
    _model.isReaded = 1;
    _model.content = localPath.split("/").last; // ??????????????????????????????
    _model.filename = filename; // ???????????????
    _model.sendState = 0;

    _model.time = DateUtil.formatDate(
      date,
      format: "yyyy-MM-dd HH:mm:ss",
    );
    _model.eventId = "${DateTime.now().millisecondsSinceEpoch}";

    _dataList.insert(0, _model);

    return _model;
  }

  // ??????????????????
  ChatRecordModel _textSendingMessage(String content) {
    ChatRecordModel _model = ChatRecordModel.fromJson({});
    _model.isMine = 1;
    _model.action = "text";
    _model.eventName = _customer ? "customer" : "chat";
    if (_customer == false) {
      _model.fromId = _chatFriendModel.userId;
    }
    _model.isReaded = 1;
    _model.content = content;
    _model.time = DateUtil.formatDate(
      DateTime.now(),
      format: "yyyy-MM-dd HH:mm:ss",
    );
    _model.sendState = 0;
    _model.eventId = "${DateTime.now().millisecondsSinceEpoch}";

    _dataList.insert(0, _model);
    setState(() {});

    return _model;
  }

  // ?????????
  void _sendTextMessage(String content, {ChatRecordModel? resendModel}) {
    ChatRecordModel _model;
    if (resendModel == null) {
      _model = _textSendingMessage(content);
      // ??????
      _appHomeController.accountDB!.insert(
        kAppChatRecordTableName,
        _model.toJson(),
      );
    } else {
      _model = resendModel;
      _model.sendState = 0;
      Get.find<AppMessageController>().update(["${_model.eventId}"]);
    }

    String _eventId = _model.eventId;
    String _fromId = _customer ? "" : _chatFriendModel.userId;
    bool _isCustomer = _customer;

    AppMessageController.encryptMessage(
      publicKey: _curvePublicKey,
      content: content,
    ).then((params) {
      if (_isCustomer == false) {
        params["to"] = _fromId;
      }

      MessageApi.sendTextMessage(_isCustomer, params: params).then((value) {
        if (mounted) {
          _model.sendState = 1;
        }

        AppMessageController.updateMessageState(
          sendState: 1,
          eventId: _eventId,
          fromId: _fromId,
          newEventId: "${value['id']}",
        );
      }).catchError((error) {
        if (mounted) {
          _model.sendState = 2;
        }
        AppMessageController.updateMessageState(
          sendState: 2,
          eventId: _eventId,
          fromId: _fromId,
          newEventId: "",
        );
      });
    });
  }

  // ????????????
  Future<void> _readMessage(ChatRecordModel _model) async {
    Completer _completer = Completer();
    String _eventName = _customer ? "customer" : "chat";
    // ??????
    if (_model.isReaded == 0) {
      _model.isReaded = 1;
      await _appHomeController.accountDB!.update(
        kAppChatRecordTableName,
        {"isReaded": 1},
        where: "eventName = '$_eventName' AND fromId = '${_model.fromId}'",
      );

      _appHomeController.unreadCount();
    }

    if (_model.isMine == 1 &&
        _model.sendState == 0 &&
        _model.action == "text") {
      await _appHomeController.accountDB!.update(
        kAppChatRecordTableName,
        {"sendState": 2},
        where:
            "eventName = '$_eventName' AND fromId = '${_model.fromId}' AND eventId = '${_model.eventId}'",
      );
    }

    _completer.complete();
    return _completer.future;
  }

  // ?????????????????????
  void _sendFilesMessage(List<String> pathList,
      {List<ChatRecordModel>? resendModelList}) async {
    Directory directory = await getTemporaryDirectory();
    String _cryptFilePath = directory.path + "/chatCryptFiles";
    var file = Directory(_cryptFilePath);
    if (file.existsSync() == false) {
      await file.create();
    }

    Map<String, dynamic> _params = {
      "config": kAppConfig,
      "rootPath": _chatRootPath + "/upload",
      "publicKey": _curvePublicKey,
      "cryptFilePath": _cryptFilePath,
    };

    if (resendModelList == null) {
      List<ChatRecordModel> _modelList = [];
      for (var i = 0; i < pathList.length; i++) {
        String _path = pathList[i];
        if (_path.length > 0) {
          ChatRecordModel _model = _fileSendingMessage(pathList[i]);
          await Future.delayed(Duration(milliseconds: 10));
          _modelList.add(_model);
          // ??????
          _appHomeController.accountDB!.insert(
            kAppChatRecordTableName,
            _model.toJson(),
          );

          if (i == pathList.length - 1) {
            SVProgressHUD.dismiss();
            setState(() {});

            _params["message"] = _modelList;
            AppMessageController.backgroudSendFileMessage(_params);
          }
        }
      }
    } else {
      resendModelList.first.sendState = 0;
      Get.find<AppMessageController>()
          .update(["${resendModelList.first.eventId}"]);

      _params["message"] = resendModelList;
      AppMessageController.backgroudSendFileMessage(_params);
    }
  }

  // ????????????
  void _sendFileAction(int index) {
    // ????????????
    void _handleFileResult(FilePickerResult result) async {
      if (result.files.length == 0) {
        return;
      }

      SVProgressHUD.show();
      QueueUtil.get("kChatSendingFile")?.addTask(() {
        return _sendFilesMessage(
            List.generate(result.files.length, (index) => index).map((index) {
          return result.files[index].path ?? "";
        }).toList());
      });
    }

    // ????????????
    void _handleAssetFile(List<File> list) async {
      if (list.length == 0) {
        return;
      }

      SVProgressHUD.show();
      QueueUtil.get("kChatSendingImage")?.addTask(() {
        return _sendFilesMessage(
            List.generate(list.length, (index) => index).map((index) {
          return list[index].path;
        }).toList());
      });
    }

    if (index == 0) {
      // ?????????
      ImagePicker.pick(context, count: 9).then((value) {
        if (value.length > 0) {
          _handleAssetFile(value);
        }
      });
    } else if (index == 1) {
      // ??????
      ImagePicker.openCamera(context).then((value) {
        if (value.length > 0) {
          _handleAssetFile(value);
        }
      });
    } else if (index == 2) {
      // ????????????
      FilePicker.platform.pickFiles(allowMultiple: true).then((result) {
        if (result != null) {
          _handleFileResult(result);
        }
      });
    }
  }

  // ??????????????????
  void _readRecord({void Function()? finish}) async {
    // ????????????????????????
    _dataList.clear();

    List _recordList = await _appHomeController.accountDB!.query(
      kAppChatRecordTableName,
      where: _customer
          ? "eventName = 'customer'"
          : "eventName = 'chat' AND fromId = '${widget.fromId}'",
    );

    for (var i = 0; i < _recordList.length; i++) {
      dynamic element = _recordList[i];
      ChatRecordModel _model = ChatRecordModel.fromJson(element ?? {});
      await _readMessage(_model);
      _dataList.insert(0, _model);

      if (_model.isMine == 0 &&
          (_model.filename.toLowerCase().contains(".jpg") ||
              _model.filename.toLowerCase().contains(".png") ||
              _model.filename.toLowerCase().contains(".jpeg") ||
              _model.filename.toLowerCase().contains(".gif"))) {
        // ????????????
        QueueUtil.get("kChatDownloadImage_${_model.eventId}")?.addTask(() {
          return _downloadFile(_model);
        });
      }

      if (i == _recordList.length - 1) {
        _dataList.sort((model1, model2) {
          return model2.time.compareTo(model1.time);
        });

        setState(() {
          _scrollController.jumpTo(0);
          if (finish != null) {
            finish();
          }
        });

        Future.delayed(Duration(milliseconds: 300), () {
          SVProgressHUD.dismiss();
        });
      }
    }

    if (_recordList.length == 0) {
      setState(() {});

      if (finish != null) {
        finish();
      }

      Future.delayed(Duration(milliseconds: 300), () {
        SVProgressHUD.dismiss();
      });
    }

    // ??????????????????
    if (_customer == false) {
      _appHomeController.accountDB!.update(
        kAppConversationTableName,
        {"unread": 0},
        where: "fromId = '${widget.fromId}'",
      );
    }
  }

  // ????????????
  void _downloadFile(ChatRecordModel _model, {bool isFile = false}) async {
    var directory = Directory(_chatRootPath + "/download");
    if (directory.existsSync() == false) {
      await directory.create();
    }

    String _filePath = _chatRootPath + "/download/${_model.content}";
    if (File(_filePath).existsSync()) {
      return;
    }

    String _eventId = _model.eventId;
    String _fromId = _model.fromId;

    _model.sendState = 3;
    Get.find<AppMessageController>().update(["${_model.eventId}"]);

    Map<String, dynamic> _params = {
      "requestPath": _model.content,
      "publicKey": _curvePublicKey,
      "salt": _model.salt,
      "downloadPath": directory.path,
      "eventId": _eventId,
      "fromId": _fromId,
      "config": kAppConfig,
    };

    void _feedBack(List value, bool error) {
      AppMessageController.updateMessageState(
        sendState: error == true ? 2 : 1,
        eventId: value[0],
        fromId: value[1],
        newEventId: "",
      );

      if (mounted && isFile) {
        // ????????????
        Get.to(
          FilePreviewPage(
            title: "????????????",
            localPath: _filePath,
          ),
        );
      }
    }

    compute(AppMessageController.chatDecryptFile, _params).then((value) {
      _feedBack(value, false);
    }).catchError((error) {
      _feedBack([_eventId, _fromId], false);
    });
  }

  // ???????????????????????????
  void _handleReceiveMessage(List<ChatRecordModel> list) async {
    List<String> _updateMessageList = [];
    for (var i = 0; i < list.length; i++) {
      ChatRecordModel _model = list[i];
      ChatRecordModel? _recordModel = _dataList
          .firstWhereOrNull((element) => element.eventId == _model.eventId);
      if (_recordModel == null) {
        _recordModel = _model;
        await _readMessage(_recordModel);
        _dataList.insert(0, _recordModel);
      } else {
        _recordModel = _model;
        _updateMessageList.add(_recordModel.eventId);
      }

      if (_recordModel.action == "file" && _recordModel.decrypt == 2) {
        if (_recordModel.filename.toLowerCase().contains(".jpg") ||
            _recordModel.filename.toLowerCase().contains(".png") ||
            _recordModel.filename.toLowerCase().contains(".jpeg") ||
            _recordModel.filename.toLowerCase().contains(".gif")) {
          // ????????????
          QueueUtil.get("kChatDownloadImage_${_recordModel.eventId}")
              ?.addTask(() {
            return _downloadFile(_recordModel!);
          });
        }
      }

      if (i == list.length - 1) {
        if (_updateMessageList.length > 0) {
          Get.find<AppMessageController>().update(
              List.generate(_updateMessageList.length, (index) => index)
                  .map((index) {
            return _updateMessageList[index];
          }).toList());
        } else {
          setState(() {
            _scrollController.jumpTo(0);
          });
        }
      }
    }
  }

  // ????????????
  void _photoBrower(String eventId) async {
    List _recordList = await _appHomeController.accountDB!.query(
      kAppChatRecordTableName,
      where: _customer
          ? "eventName = 'customer' AND action = 'file' AND (isMine = '1' OR (isMine = '0' AND sendState = '1'))"
          : "eventName = 'chat' AND fromId = '${widget.fromId}' AND action = 'file' AND sendState = '1' AND (isMine = '1' OR (isMine = '0' AND sendState = '1'))",
      columns: ["isMine", "content", "eventId"],
    );

    List<File> _filePathList = [];
    if (_recordList.length > 50) {
      SVProgressHUD.show();
    }

    int _index =
        _recordList.indexWhere((element) => element["eventId"] == eventId);
    for (var i = 0; i < _recordList.length; i++) {
      var _object = _recordList[i];
      String _filePath = "";
      if (_object["isMine"] == 0) {
        // ?????????????????????
        _filePath = _chatRootPath + "/download/${_object['content']}";
      } else {
        // ????????????????????????
        _filePath = _chatRootPath + "/upload/${_object['content']}";
      }

      _filePathList.add(File(_filePath));

      if (i == _recordList.length - 1) {
        SVProgressHUD.dismiss();

        PhotoViewGalleryPage.show(
          context,
          PhotoViewGalleryPage(
            images: _filePathList,
            initIndex: (_index < 0)
                ? 0
                : (_index > _filePathList.length - 1)
                    ? _filePathList.length - 1
                    : _index,
          ),
        );
      }
    }
  }

  // ??????????????????
  void _friendUpdate(FriendModel _friendModel) {
    // ??????????????????
    bool _refresh = false;
    _curvePublicKey = _friendModel.key;
    _chatFriendModel.risk = _friendModel.risk;

    if (_chatFriendModel.key != _friendModel.key) {
      _chatFriendModel.key = _friendModel.key;
      _refresh = true;
    }

    if (_chatFriendModel.avatar != _friendModel.avatar) {
      _chatFriendModel.avatar = _friendModel.avatar;
      _refresh = true;
    }

    if (_chatFriendModel.nickname != _friendModel.nickname) {
      _chatFriendModel.nickname = _friendModel.nickname;
      _refresh = true;
    }

    if (_chatFriendModel.remark != _friendModel.remark) {
      _chatFriendModel.remark = _friendModel.remark;
      _refresh = true;
    }

    if (_chatFriendModel.updateState != _friendModel.updateState) {
      _chatFriendModel.updateState = _friendModel.updateState;
      _refresh = true;
    }

    if (_chatFriendModel.timeout != _friendModel.timeout) {
      _chatFriendModel.timeout = _friendModel.timeout;
    }

    if (_friendModel.userId.length == 0 ||
        _friendModel.key.length == 0 ||
        _friendModel.updateState == 0) {
      if (_inputController.inputState != ChatInputState.none) {
        _inputController.hideKeyboard();
      }
    }

    if (_refresh == true) {
      _appHomeController.update(["kFriendInfoUpdate"]);
    }
  }

  @override
  void initState() {
    super.initState();

    SVProgressHUD.show();
    Get.put(AppMessageController());
    _customer = widget.fromId == null;
    StorageUtils.getChatObjectPath(_customer ? "customer" : widget.fromId!)
        .then((path) async {
      _chatRootPath = path;

      if (_customer) {
        _curvePublicKey = kAppConfig.assistantCurvePublicKey;
      } else {
        if ((widget.fromAlert ?? false) == true) {
          Get.find<AppHomeController>().messageHandler.add({
            StreamActionType.system: MessageModel.fromJson({})
              ..action = "readed"
              ..fromId = widget.fromId!
          });
        }
        // ????????????
        List _friends = await _appHomeController.accountDB!.query(
          kAppFriendTableName,
          where: "userId = '${widget.fromId}'",
          limit: 1,
          columns: [
            "userId",
            "key",
            "remark",
            "mobile",
            "nickname",
            "avatar",
            "tags",
            "updateState",
            "timeout",
          ],
        );

        if (_friends.length > 0) {
          _chatFriendModel = FriendModel.fromJson(_friends.first ?? {});
          _curvePublicKey = _chatFriendModel.key;
        }
      }

      Future(() {
        if (_customer) {
          _readRecord();
        } else {
          if (_chatFriendModel.userId.length == 0 ||
              _chatFriendModel.key.length == 0) {
            SVProgressHUD.dismiss();
            setState(() {});
          } else {
            _readRecord();
          }
        }
      });

      // ????????????
      _messageSubscription =
          _appHomeController.chatHandler.stream.listen((event) async {
        debugPrint("??????????????????????????????");
        if (_customer) {
          // ??????
          if (event.containsKey(StreamActionType.customer)) {
            debugPrint("?????????????????????");
            if (event[StreamActionType.customer] is List<ChatRecordModel>) {
              List<ChatRecordModel> _list = event[StreamActionType.customer];
              _handleReceiveMessage(_list);
            } else {
              ChatRecordModel _model = event[StreamActionType.customer];
              _handleReceiveMessage([_model]);
            }
          } else if (event.containsKey(StreamActionType.sendChat)) {
            // ????????????????????????
            debugPrint("????????????????????????");
            ChatRecordModel? _eventModel = event[StreamActionType.sendChat];
            if (_eventModel != null) {
              ChatRecordModel? _model = _dataList.firstWhereOrNull(
                  (element) => element.eventId == _eventModel.eventId);
              if (_model != null) {
                _model.sendState = _eventModel.sendState;
                String _eventId = _model.eventId;
                if (_eventModel.newEventId.length > 0) {
                  _model.eventId = _eventModel.newEventId;
                }

                Get.find<AppMessageController>()
                    .update(["${_model.eventId}", "$_eventId"]);
              }
            }
          }
        } else {
          // ??????
          if (event.containsKey(StreamActionType.chat)) {
            debugPrint("?????????????????????");
            if (event[StreamActionType.chat] is List<ChatRecordModel>) {
              List<ChatRecordModel> _list = event[StreamActionType.chat];
              _handleReceiveMessage(_list);
            } else {
              ChatRecordModel _model = event[StreamActionType.chat];
              _handleReceiveMessage([_model]);
            }
          } else if (event.containsKey(StreamActionType.sendChat)) {
            // ????????????????????????
            debugPrint("????????????????????????");
            ChatRecordModel? _eventModel = event[StreamActionType.sendChat];
            if (_eventModel != null) {
              ChatRecordModel? _model = _dataList.firstWhereOrNull(
                  (element) => element.eventId == _eventModel.eventId);
              if (_model != null) {
                _model.sendState = _eventModel.sendState;
                String _eventId = _model.eventId;
                if (_eventModel.newEventId.length > 0) {
                  _model.eventId = _eventModel.newEventId;
                }

                Get.find<AppMessageController>()
                    .update(["${_model.eventId}", "$_eventId"]);
              }
            }
          }
        }
      });

      // ????????????
      _systemSubscription =
          _appHomeController.messageHandler.stream.listen((event) {
        debugPrint("??????????????????????????????");
        if (event.containsKey(StreamActionType.system)) {
          var _object = event[StreamActionType.system]!;
          if (_customer) {
            // ??????
            debugPrint("????????????");
            if (_inputController.inputState != ChatInputState.none) {
              _inputController.inputState = ChatInputState.none;
            }

            if (_object == SystemStreamActionType.customerSwitch) {
              _appHomeController.update(["kFriendInfoUpdate"]);

              _readRecord(
                finish: () {
                  // ??????????????????????????????
                  ChatRecordModel _model = ChatRecordModel.fromJson({});
                  _model.eventName = "customer_switch";
                  _model.content = "??????????????????${kAppConfig.assistantNickName}";
                  _dataList.insert(0, _model);

                  setState(() {
                    _scrollController.jumpTo(0);
                  });
                },
              );
            } else if (_object == SystemStreamActionType.customerEnd) {
              // ??????????????????????????????
              ChatRecordModel _model = ChatRecordModel.fromJson({});
              _model.eventName = "customer_switch";
              _model.content = "?????????????????????";
              _dataList.insert(0, _model);

              setState(() {
                _scrollController.jumpTo(0);
              });
            }
          } else {
            // ??????
            if (_object is FriendModel) {
              FriendModel _friendModel = _object;
              if (_friendModel.userId == _chatFriendModel.userId) {
                // ??????????????????
                _friendUpdate(_friendModel);
              }
            } else if (_object is List<FriendModel>) {
              FriendModel? _friendModel = _object.firstWhereOrNull(
                  (element) => element.userId == _chatFriendModel.userId);
              if (_friendModel != null) {
                // ??????????????????
                _friendUpdate(_friendModel);
              }
            } else if (_object == SystemStreamActionType.emptyMessage) {
              // ??????????????????
              _readRecord();
            } else if (_object is List<String>) {
              List<String> _list = _object;
              var _userId = _list.firstWhereOrNull(
                  (element) => element == _chatFriendModel.userId);
              if (_userId != null) {
                _chatFriendModel.updateState = 0;
                _appHomeController.update(["kFriendInfoUpdate"]);
              }
            }
          }
        } else if (event.containsKey(StreamActionType.cleanMessage)) {
          // ??????????????????????????????
          _readRecord();
        } else if (event.containsKey(StreamActionType.messageDestroy)) {
          var _object = event[StreamActionType.messageDestroy]!;
          if (_object is Map) {
            if (_object.containsKey("eventId") == false) {
              // ????????????????????????
              if (_customer == true || widget.fromId == _object["fromId"]) {
                _readRecord();
              }
            } else {
              // ??????????????????
              if (_customer == true || _object["fromId"] == widget.fromId) {
                _dataList.removeWhere(
                    (element) => element.eventId == _object["eventId"]);
                setState(() {});
              }
            }
          } else if (_object is List) {
            for (var i = 0; i < _object.length; i++) {
              var data = _object[i];
              if (data["fromId"] == widget.fromId) {
                _dataList.removeWhere(
                    (element) => element.eventId == data["eventId"]);

                if (i == _object.length - 1) {
                  setState(() {});
                }
              }
            }
          }
        } else if (event.containsKey(StreamActionType.friendDelete)) {
          // ????????????
          var _fromId = event[StreamActionType.friendDelete]!;
          if (_fromId == _chatFriendModel.userId) {
            Get.back();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    Get.delete<AppMessageController>();
    _messageSubscription?.cancel();
    _systemSubscription?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: _customer
          ? CustomerHeaderBar(
              onTap: () {
                _inputController.hideKeyboard();
              },
            ).init(context)
          : AppBar(
              title: GetBuilder<AppHomeController>(
                id: "kFriendInfoUpdate",
                builder: (controller) {
                  return Text(
                      "${_chatFriendModel.remark.length == 0 ? _chatFriendModel.nickname : _chatFriendModel.remark}");
                },
              ),
              leading: AppbarBack(),
              actions: [
                MaterialButton(
                  onPressed: () {
                    Get.to(ChatSettingPage(friendModel: _chatFriendModel));
                  },
                  minWidth: 44.w,
                  height: 44.w,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(44.w / 2),
                  ),
                  child: Image.asset(
                    "images/chat_more@2x.png",
                    width: 26.w,
                  ),
                ),
                SizedBox(width: 5.w),
              ],
            ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ????????????
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_inputController.inputState != ChatInputState.none) {
                  _inputController.hideKeyboard();
                }
              },
              onPanEnd: (details) {
                if (_scrollController.hasClients &&
                    _inputController.inputState != ChatInputState.none) {
                  _inputController.hideKeyboard();
                }
              },
              child: Container(
                alignment: Alignment.topCenter,
                color: const Color(0xFFEFEFEF),
                child: NotificationListener(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification &&
                        _scrollController.hasClients &&
                        _inputController.inputState != ChatInputState.none) {
                      _inputController.hideKeyboard();
                    }

                    return true;
                  },
                  child: ListView.separated(
                    physics: BouncingScrollPhysics(),
                    reverse: true,
                    padding: EdgeInsets.fromLTRB(
                      12.w,
                      14.w,
                      12.w,
                      12.w,
                    ),
                    itemBuilder: (context, index) {
                      ChatRecordModel _model = _dataList[index];
                      return (_model.decrypt == 0 && _model.isMine == 0)
                          ? SizedBox()
                          : ChatItemWidget(
                              recordModel: _model,
                              friendModel: _customer ? null : _chatFriendModel,
                              chatRootPath: _chatRootPath,
                              downloadAction: (isFile) {
                                QueueUtil.get(
                                        "kChatDownloadFile_${_model.eventId}")
                                    ?.addTask(() {
                                  return _downloadFile(_model, isFile: isFile);
                                });
                              },
                              resendAction: () {
                                if (_model.action == "text") {
                                  _sendTextMessage(
                                    _model.content,
                                    resendModel: _model,
                                  );
                                } else if (_model.action == "file") {
                                  _sendFilesMessage([],
                                      resendModelList: [_model]);
                                }
                              },
                              deleteAction: () {
                                void _localDelete() {
                                  StorageUtils.deleteMessage(
                                    _customer,
                                    _model.fromId,
                                    _model.eventId,
                                  ).then((eventId) {
                                    if (eventId.length > 0) {
                                      _appHomeController.messageHandler.add({
                                        StreamActionType.messageDestroy: {
                                          "fromId": _model.fromId,
                                          "eventId": _model.eventId,
                                        }
                                      });
                                    }
                                  });

                                  SVProgressHUD.dismiss();
                                }

                                if (_model.sendState == 2 || _customer) {
                                  _localDelete();
                                } else {
                                  SVProgressHUD.show();
                                  MessageApi.report(params: {
                                    "data": _model.eventId,
                                    "type": "destroy",
                                  }).then((value) {
                                    _localDelete();
                                  }).catchError((error) {
                                    SVProgressHUD.dismiss();
                                  });
                                }
                              },
                              photoBrowerAction: () {
                                _photoBrower(_model.eventId);
                              },
                            );
                    },
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 22.w);
                    },
                    itemCount: _dataList.length,
                    controller: _scrollController,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                  ),
                ),
              ),
            ),
          ),
          // ?????????
          Stack(
            alignment: Alignment.center,
            children: [
              ChatInputWidget(
                controller: _inputController,
                customer: _customer,
                sendTextHandler: (content) {
                  _sendTextMessage(content);
                },
                sendFileHandler: (index) {
                  _sendFileAction(index);
                },
                inputShowFeedback: () {
                  _scrollController.jumpTo(0);
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: GetBuilder<AppHomeController>(
                  id: "kFriendInfoUpdate",
                  builder: (controller) {
                    return controller.sseState != 1 ||
                            (_customer == false &&
                                (_chatFriendModel.userId.length == 0 ||
                                    _chatFriendModel.key.length == 0 ||
                                    _chatFriendModel.updateState == 0))
                        ? Container(
                            color: Colors.black12,
                            child: GestureDetector(
                              onTap: (_customer == false &&
                                      (_chatFriendModel.userId.length == 0 ||
                                          _chatFriendModel.key.length == 0 ||
                                          _chatFriendModel.updateState == 0))
                                  ? () {
                                      if (_inputController.inputState !=
                                          ChatInputState.none) {
                                        _inputController.hideKeyboard();
                                      }

                                      SVProgressHUD.show();
                                      _appHomeController.friendsItems([
                                        _chatFriendModel.userId
                                      ]).then((value) {
                                        if (value.length > 0) {
                                          _appHomeController.messageHandler
                                              .add({
                                            StreamActionType.system: value,
                                          });
                                        }

                                        SVProgressHUD.dismiss();
                                      });
                                    }
                                  : null,
                            ),
                          )
                        : SizedBox();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
