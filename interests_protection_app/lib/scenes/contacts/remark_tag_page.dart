import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';

import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/scenes/contacts/tag_manager_page.dart';
import 'package:interests_protection_app/scenes/contacts/widgets/tag_selection_item.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';

class RemarkTagPage extends StatefulWidget {
  final FriendModel friendModel;
  const RemarkTagPage({super.key, required this.friendModel});

  @override
  State<RemarkTagPage> createState() => _RemarkTagPageState();
}

class _RemarkTagPageState extends State<RemarkTagPage> {
  TextEditingController _remarkEditingController = TextEditingController();
  final AppHomeController _homeController = Get.find<AppHomeController>();
  bool _canSubmit = false;
  List<String> _friendTagList = [];

  // 校验
  void _checkAviable({bool checkList = false}) {
    String _remark = widget.friendModel.remark;
    var _tags = jsonDecode(widget.friendModel.tags);
    List<String> _tagList =
        List.from(_tags is String ? jsonDecode(_tags) : _tags);
    _tagList.removeWhere((element) => element.replaceAll(" ", "").length == 0);

    if (_remarkEditingController.text.trim().length > 0 &&
        _remarkEditingController.text != _remark) {
      _canSubmit = true;

      if (_tagList == _friendTagList) {
        _canSubmit = false;
      }
    } else {
      _canSubmit = false;

      if (_tagList != _friendTagList) {
        _canSubmit = true;
      }
    }

    if (checkList) {
      if (_tagList != _friendTagList) {
        _canSubmit = true;
      } else {
        _canSubmit = false;
      }
    }

    setState(() {});
  }

  void _onSubmit() {
    Map<String, dynamic> _params = {"fid": widget.friendModel.userId};
    _friendTagList
        .removeWhere((element) => element.replaceAll(" ", "").length == 0);

    _params["tags"] = _friendTagList;
    _params["remark"] = _remarkEditingController.text;
    _params["nickname"] = widget.friendModel.nickname;
    _params["mobile"] = widget.friendModel.mobile;

    if (_params.length > 0) {
      FocusScope.of(context).requestFocus(FocusNode());

      SVProgressHUD.show();
      AccountApi.updateFriendsInfo(params: _params).then((value) async {
        // 更新用户信息数据库
        List _list = await _homeController.accountDB!.query(
          kAppFriendTableName,
          where: "userId = '${widget.friendModel.userId}'",
          limit: 1,
        );

        if (_list.length == 1) {
          Map<String, dynamic> _infoParams = Map<String, dynamic>.from(_params);
          _infoParams.remove("fid");

          _infoParams["tags"] = jsonEncode(_params["tags"]);
          widget.friendModel.tags = jsonEncode(_params["tags"]);
          widget.friendModel.remark = _params["remark"];

          await _homeController.accountDB!.update(
            kAppFriendTableName,
            _infoParams,
            where: "userId = '${widget.friendModel.userId}'",
          );

          // 好友资料更新
          _homeController.messageHandler.add({
            StreamActionType.system: widget.friendModel,
          });
        }

        SVProgressHUD.dismiss();

        _canSubmit = false;
        setState(() {
          Get.back();
        });
      }).catchError((error) {
        SVProgressHUD.dismiss();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    var _tags = jsonDecode(widget.friendModel.tags);
    _friendTagList = List.from(_tags.runtimeType == String
        ? ("$_tags".length == 0 ? [] : jsonDecode(_tags))
        : _tags);
    _friendTagList
        .removeWhere((element) => element.replaceAll(" ", "").length == 0);

    String _remark = widget.friendModel.remark;
    _remarkEditingController.text = _remark;
  }

  @override
  void dispose() {
    _remarkEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("备注与标签"),
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
            children: [
              SizedBox(height: 14.w),
              // 备注
              Container(
                color: const Color(0xFFFFFFFF),
                height: 56.w,
                padding: EdgeInsets.only(left: 16.w, right: 16.w),
                child: Row(
                  children: [
                    Text(
                      "备注",
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
                              controller: _remarkEditingController,
                              style: TextStyle(
                                color: const Color(0xFF000000),
                                fontSize: 15.sp,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "设置备注",
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
                                  _remarkEditingController.clear();
                                } else if (_canSubmit) {
                                  _onSubmit();
                                }
                              },
                            ),
                          ),
                          _remarkEditingController.text.trim().length > 0
                              ? SizedBox(
                                  width: 34.w,
                                  height: 34.w,
                                  child: Center(
                                    child: InkWell(
                                      onTap: () {
                                        _remarkEditingController.clear();
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
              SizedBox(height: 14.w),
              // 标签
              TagSelectionItem(
                tagList: _friendTagList,
                onTab: () {
                  FocusScope.of(context).requestFocus(FocusNode());

                  Navigator.of(context)
                      .push(MaterialPageRoute(
                    builder: (context) {
                      return TagManagerPage(
                        selectTabList: _friendTagList,
                      );
                    },
                    fullscreenDialog: true,
                  ))
                      .then((value) {
                    if (value is List) {
                      _friendTagList = List<String>.from(value);
                      _checkAviable(checkList: true);
                    }
                  });
                },
                onDelete: (index) {
                  AlertVeiw.show(
                    context,
                    confirmText: "确认",
                    contentText: "是否删除该标签?",
                    cancelText: "取消",
                    confirmAction: () {
                      _friendTagList.removeAt(index);
                      _checkAviable(checkList: true);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
