import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/scenes/contacts/friend_list_page.dart';
import 'package:interests_protection_app/scenes/contacts/widgets/friend_list_item.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';

class TagCreatePage extends StatefulWidget {
  final FriendTagModel? tagModel;
  const TagCreatePage({super.key, this.tagModel});

  @override
  State<TagCreatePage> createState() => _TagCreatePageState();
}

class _TagCreatePageState extends State<TagCreatePage> {
  TextEditingController _tagEditingController = TextEditingController();
  AppHomeController _homeController = Get.find<AppHomeController>();
  bool _canSubmit = false;
  List<FriendModel> _memberList = [];
  List<FriendModel> _removeMemberList = [];

  void _onSubmit() async {
    void _updateTagRecord() async {
      var _list = await _homeController.accountDB!.query(
        kAppTagboardTableName,
        where: "label = '${_tagEditingController.text}'",
        limit: 1,
      );

      if (_list.length > 0 && widget.tagModel == null) {
        utilsToast(msg: "已存在该标签");
        _canSubmit = false;
        setState(() {});
        return;
      }

      if (widget.tagModel != null) {
        _homeController.accountDB!
            .update(
          kAppTagboardTableName,
          {"label": _tagEditingController.text},
          where: "id = '${widget.tagModel!.id}'",
        )
            .then((value) {
          Get.back(result: true);
        });
      } else {
        _homeController.accountDB!.insert(
          kAppTagboardTableName,
          {"label": _tagEditingController.text},
        ).then((value) {
          Get.back(result: true);
        });
      }
    }

    if (_memberList.length > 0) {
      SVProgressHUD.show();

      Future<int> _updateFriend(FriendModel friendModel, bool remove) {
        Completer<int> _completer = Completer();

        String _tag = _tagEditingController.text;
        var _tags = jsonDecode(friendModel.tags);
        List<String> _oldTags = List.from(_tags.runtimeType == String
            ? ("$_tags".length == 0 ? [] : jsonDecode(_tags))
            : _tags);
        _oldTags
            .removeWhere((element) => element.replaceAll(" ", "").length == 0);

        if (remove == true) {
          _oldTags.removeWhere((element) => element == widget.tagModel!.label);
        } else {
          if (widget.tagModel != null) {
            _oldTags
                .removeWhere((element) => element == widget.tagModel!.label);
          }

          if (_oldTags.contains(_tag) == false) {
            _oldTags.add(_tag);
          }
        }

        Map<String, dynamic> _params = {"fid": friendModel.userId};
        _params["tags"] = _oldTags;
        _params["remark"] = friendModel.remark;
        _params["nickname"] = friendModel.nickname;
        _params["mobile"] = friendModel.mobile;

        AccountApi.updateFriendsInfo(
          params: _params,
          isShowErr: false,
        ).then((value) {
          _homeController.accountDB!.update(
            kAppFriendTableName,
            {"tags": jsonEncode(_oldTags)},
            where: "userId = '${friendModel.userId}'",
          );
          _completer.complete(1);
        }).catchError((error) {
          _completer.complete(0);
        });

        return _completer.future;
      }

      void _memberAction() {
        for (var i = 0; i < _memberList.length; i++) {
          QueueUtil.get("kFriendInfo_${_memberList[i].userId}")?.addTask(() {
            return _updateFriend(_memberList[i], false).then((value) {
              if (i == _memberList.length - 1) {
                _updateTagRecord();
                SVProgressHUD.dismiss();
              }
            });
          });
        }
      }

      if (_removeMemberList.length > 0) {
        for (var i = 0; i < _removeMemberList.length; i++) {
          QueueUtil.get("kFriendRemove_${_removeMemberList[i].userId}")
              ?.addTask(() {
            return _updateFriend(_removeMemberList[i], true).then((value) {
              if (i == _removeMemberList.length - 1) {
                _memberAction();
              }
            });
          });
        }
      } else {
        _memberAction();
      }
    } else {
      _updateTagRecord();
    }
  }

  void _checkAviable() {
    if (_tagEditingController.text.trim().length > 0) {
      _canSubmit = true;
    } else {
      _canSubmit = false;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    if (widget.tagModel != null) {
      _tagEditingController.text = widget.tagModel!.label;
      // 好友信息
      widget.tagModel!.friends.forEach((element) {
        _memberList.add(element);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(widget.tagModel != null ? "编辑标签" : "新建标签"),
        leadingWidth: 64.w,
        leading: Center(
          child: MaterialButton(
            onPressed: () {
              Get.back();
            },
            minWidth: 44.w,
            height: 44.w,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(44.w / 2),
            ),
            child: Text(
              "取消",
              style: TextStyle(
                fontSize: 15.sp,
                color: const Color(0xFF000000),
              ),
            ),
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: _canSubmit
                ? () {
                    _onSubmit();
                  }
                : null,
            minWidth: 44.w,
            height: 44.w,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(44.w / 2),
            ),
            child: Text(
              "完成",
              style: TextStyle(
                fontSize: 15.sp,
                color: _canSubmit
                    ? const Color(0xFF000000)
                    : kAppConfig.appPlaceholderColor,
              ),
            ),
          ),
          SizedBox(width: 11.w),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Container(
          color: const Color(0xFFFAFAFA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 14.w),
              //  标签名称
              Container(
                color: const Color(0xFFFFFFFF),
                height: 56.w,
                padding: EdgeInsets.only(left: 16.w, right: 16.w),
                child: Row(
                  children: [
                    Text(
                      "标签名称",
                      style: TextStyle(
                        color: const Color(0xFF808080),
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagEditingController,
                              style: TextStyle(
                                color: const Color(0xFF000000),
                                fontSize: 15.sp,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "",
                                hintStyle: TextStyle(
                                  color: kAppConfig.appPlaceholderColor,
                                  fontSize: 15.sp,
                                ),
                              ),
                              onChanged: (value) {
                                _checkAviable();
                              },
                              onSubmitted: (value) {
                                if (value == " " || value.trim().length == 0) {
                                  _tagEditingController.clear();
                                } else if (_canSubmit) {
                                  _onSubmit();
                                }
                              },
                            ),
                          ),
                          _tagEditingController.text.trim().length > 0
                              ? SizedBox(
                                  width: 34.w,
                                  height: 34.w,
                                  child: Center(
                                    child: InkWell(
                                      onTap: () {
                                        _tagEditingController.clear();
                                        _checkAviable();
                                      },
                                      child: Image.asset(
                                        "images/login_clean@2x.png",
                                        width: 14.w,
                                        height: 14.w,
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.w, 16.w, 5.w),
                child: Text(
                  "标签成员",
                  style: TextStyle(
                    color: const Color(0xFFA6A6A6),
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  border: Border(
                    bottom: BorderSide(
                      width: 0.5.w,
                      color: const Color(0xFFF7F7F7),
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Expanded(
                      child: MaterialButton(
                        height: 75.w,
                        padding: EdgeInsets.only(left: 29.w),
                        onPressed: () {
                          FocusScope.of(context).requestFocus(FocusNode());

                          Get.to(
                            FriendListPage(
                              selectionFeedback: (friendModel) {
                                FriendModel? _existModel =
                                    _memberList.firstWhereOrNull((element) =>
                                        element.userId == friendModel.userId);
                                if (_existModel == null) {
                                  _memberList.add(friendModel);

                                  var _tags = jsonDecode(friendModel.tags);
                                  String _tag = _tagEditingController.text;
                                  List<String> _oldTags = List.from(
                                      _tags.runtimeType == String
                                          ? ("$_tags".length == 0
                                              ? []
                                              : jsonDecode(_tags))
                                          : _tags);
                                  _oldTags.removeWhere((element) =>
                                      element.replaceAll(" ", "").length == 0);

                                  if (_oldTags.contains(_tag) == false) {
                                    _oldTags.add(_tag);
                                    friendModel.tags = jsonEncode(_oldTags);
                                    _memberList.last = friendModel;
                                  }
                                }

                                _checkAviable();
                              },
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              "images/tag_new@2x.png",
                              width: 30.w,
                              height: 30.w,
                            ),
                            SizedBox(width: 22.w),
                            Text(
                              "添加成员",
                              style: TextStyle(
                                color: kAppConfig.appThemeColor,
                                fontSize: 18.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  itemBuilder: (context, index) {
                    FriendModel _model = _memberList[index];
                    return FriendListItem(
                      friendModel: _model,
                      feedback: () {
                        AlertVeiw.show(
                          context,
                          confirmText: "确定",
                          contentText: "是否删除该成员？",
                          cancelText: "取消",
                          confirmAction: () {
                            _memberList.removeAt(index);
                            if (widget.tagModel != null) {
                              var _tags = jsonDecode(_model.tags);
                              List<String> _oldTags = List.from(
                                  _tags.runtimeType == String
                                      ? ("$_tags".length == 0
                                          ? []
                                          : jsonDecode(_tags))
                                      : _tags);
                              _oldTags.removeWhere((element) =>
                                  element == widget.tagModel!.label);
                              _oldTags.removeWhere((element) =>
                                  element.replaceAll(" ", "").length == 0);

                              _model.tags = jsonEncode(_oldTags);

                              widget.tagModel!.friends.forEach((element) {
                                if (element.userId == _model.userId) {
                                  element.tags = _model.tags;
                                  _removeMemberList.add(element);
                                }
                              });

                              _canSubmit = true;
                            }
                            setState(() {});
                          },
                        );
                      },
                    );
                  },
                  itemCount: _memberList.length,
                ),
              ),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
