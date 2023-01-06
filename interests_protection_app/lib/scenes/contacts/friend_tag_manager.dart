import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';

import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/scenes/contacts/tag_create_page.dart';
import 'package:interests_protection_app/scenes/contacts/widgets/friend_tag_item.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/refresh_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class FriendTagManager extends StatefulWidget {
  const FriendTagManager({super.key});

  @override
  State<FriendTagManager> createState() => _FriendTagManagerState();
}

class _FriendTagManagerState extends State<FriendTagManager> {
  final AppHomeController _appHomeController = Get.find<AppHomeController>();
  late StreamSubscription? _systemStreamSubscription;

  RefreshUtilController _refreshController =
      RefreshUtilController(initialRefresh: true);
  AppHomeController _homeController = Get.find<AppHomeController>();
  TextEditingController _textEditingController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  bool _edittingRecord = false;

  List<FriendTagModel> _dataList = [];
  List<FriendTagModel> _selectList = [];
  String _keyword = "";

  // 标签记录
  void _loadRecord() async {
    _dataList.clear();
    _selectList.clear();

    List<Map<String, Object?>> _list = await _homeController.accountDB!.query(
      kAppTagboardTableName,
      columns: ["label", "id"],
    );

    for (var i = 0; i < _list.length; i++) {
      var value = _list[i];
      String _tag = "${value['label'] ?? ''}";
      if (_tag.length > 0) {
        FriendTagModel _tagModel = FriendTagModel.fromJson({});
        _tagModel.label = _tag;
        _tagModel.id = "${value['id']}";

        List<FriendModel> _nameList = [];
        List<Map<String, Object?>> _friends =
            await _homeController.accountDB!.query(
          kAppFriendTableName,
          where: "tags LIKE '%$_tag%'",
          columns: ["nickname", "userId", "remark", "tags", "avatar"],
        );

        _friends.forEach((friend) {
          FriendModel friendModel = FriendModel.fromJson(friend);
          var _tags = jsonDecode(friendModel.tags);
          List<String> _oldTags =
              List.from(_tags is String ? jsonDecode(_tags) : _tags);
          _oldTags.removeWhere(
              (element) => element.replaceAll(" ", "").length == 0);

          if (_oldTags.contains(_tag) == true) {
            _nameList.add(FriendModel.fromJson(friend));
          }
        });

        _tagModel.friends = _nameList;
        _dataList.add(_tagModel);
      }

      if (i == _list.length - 1) {
        _refreshController.refreshCompleted();
        setState(() {});

        if (_dataList.length == 0) {
          _refreshController.status = RefreshUtilStatus.emptyData;
        }
      }
    }

    if (_list.length == 0) {
      _refreshController.refreshCompleted();
      setState(() {});

      _refreshController.status = RefreshUtilStatus.emptyData;
    }
  }

  // 删除标签
  void _tagDelete() {
    Future<String> _updateTag(FriendTagModel tagModel) {
      Completer<String> _completer = Completer();

      void _deleteTagDatabase() {
        _homeController.accountDB!
            .delete(
          kAppTagboardTableName,
          where: "id = '${tagModel.id}'",
        )
            .then((value) {
          if (value > 0) {
            _completer.complete("${tagModel.id}");
          } else {
            _completer.complete("");
          }
        }).catchError((error) {
          _completer.complete("");
        });
      }

      if (tagModel.friends.length > 0) {
        Future<int> _deleteFriendTag(FriendModel friendModel) {
          Completer<int> _completer1 = Completer();

          var _tags = jsonDecode(friendModel.tags);
          List<String> _oldTags =
              List.from(_tags is String ? jsonDecode(_tags) : _tags);
          _oldTags.removeWhere(
              (element) => element.replaceAll(" ", "").length == 0);
          _oldTags.removeWhere((element) => element == tagModel.label);

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
            _completer1.complete(1);
          }).catchError((error) {
            _completer1.complete(0);
          });

          return _completer1.future;
        }

        for (var i = 0; i < tagModel.friends.length; i++) {
          QueueUtil.get("kFriendTagDelete_${tagModel.friends[i].userId}")
              ?.addTask(() {
            return _deleteFriendTag(tagModel.friends[i]).then((value) {
              if (i == tagModel.friends.length - 1) {
                _deleteTagDatabase();
              }
            });
          });
        }
      } else {
        _deleteTagDatabase();
      }

      return _completer.future;
    }

    SVProgressHUD.show();
    int length = _selectList.length;
    for (var i = 0; i < length; i++) {
      QueueUtil.get("kTagDelete_${_selectList[i].id}")?.addTask(() {
        return _updateTag(_selectList[i]).then((value) {
          if (value.length > 0) {
            _selectList.removeWhere((element) => element.id == value);
            _dataList.removeWhere((element) => element.id == value);
          }

          if (i == length - 1) {
            _edittingRecord = false;
            if (_dataList.length == 0) {
              _refreshController.status = RefreshUtilStatus.emptyData;
            }
            setState(() {});
            SVProgressHUD.dismiss();
          }
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });

    // 好友信息更新通知
    _systemStreamSubscription =
        _appHomeController.messageHandler.stream.listen((event) {
      if (event.containsKey(StreamActionType.system)) {
        var _object = event[StreamActionType.system]!;
        if (_object == SystemStreamActionType.friendAdd) {
          _refreshController.requestRefresh();
        } else if (_object is FriendModel) {
          _dataList.forEach((element) {
            element.friends.forEach((friend) {
              if (friend.userId == _object.userId) {
                // 好友消息更新
                friend.avatar = _object.avatar;
                friend.nickname = _object.nickname;
                friend.key = _object.key;
                friend.remark = _object.remark;

                if (friend.tags != _object.tags) {
                  _refreshController.requestRefresh();
                } else {
                  setState(() {});
                }
              }
            });
          });
        } else if (_object is List<FriendModel>) {
          _refreshController.requestRefresh();
        }
      }
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _refreshController.dispose();
    _scrollController.dispose();
    _systemStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("好友标签"),
        leading: AppbarBack(),
      ),
      body: Column(
        children: [
          // 搜索
          IgnorePointer(
            ignoring: _edittingRecord,
            child: Container(
              margin: EdgeInsets.fromLTRB(10.w, 12.w, 10.w, 12.w),
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(40.w / 2),
                border: Border.all(
                  width: 0.5.w,
                  color: const Color(0xFFE8E8E8),
                ),
              ),
              padding: EdgeInsets.only(left: 14.w, right: 14.w),
              child: Row(
                children: [
                  Image.asset(
                    "images/friend_search@2x.png",
                    width: 17.w,
                    height: 17.w,
                  ),
                  SizedBox(width: 11.w),
                  Expanded(
                    child: TextField(
                      controller: _textEditingController,
                      style: TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: 15.sp,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "搜索标签",
                        hintStyle: TextStyle(
                          color: const Color(0xFFE9E9E9),
                          fontSize: 15.sp,
                        ),
                      ),
                      onChanged: (value) {
                        if (value == " " || value.trim().length == 0) {
                          _textEditingController.clear();
                          _keyword = "";
                        } else if (value.trim().length > 0) {
                          _keyword = value;
                        }

                        setState(() {});
                      },
                    ),
                  ),
                  _textEditingController.text.length > 0
                      ? InkWell(
                          onTap: () {
                            _textEditingController.clear();
                            _keyword = "";
                            setState(() {});
                          },
                          child: Image.asset(
                            "images/scan_close@2x.png",
                            width: 16.w,
                            height: 16.w,
                          ),
                        )
                      : SizedBox(),
                ],
              ),
            ),
          ),
          // 标签、好友
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              onPanEnd: (details) {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: Container(
                color: const Color(0xFFFAFAFA),
                child: RefreshUtilWidget(
                  onRefresh: _loadRecord,
                  refreshController: _refreshController,
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    padding: EdgeInsets.zero,
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      FriendTagModel _tag = _dataList[index];
                      return FriendTagItem(
                        tag: _tag,
                        keyword: _keyword,
                        edittingFeedback: _edittingRecord == true
                            ? () {
                                if (_selectList.contains(_tag)) {
                                  _selectList.remove(_tag);
                                } else {
                                  _selectList.add(_tag);
                                }

                                setState(() {});
                              }
                            : null,
                        selectFeedback: _edittingRecord == true
                            ? null
                            : () {
                                Get.to(TagCreatePage(tagModel: _tag))
                                    ?.then((value) {
                                  if (value == true) {
                                    _refreshController.requestRefresh();
                                  }
                                });
                              },
                        selected: _selectList.contains(_tag),
                      );
                    },
                    itemCount: _dataList.length,
                  ),
                ),
              ),
            ),
          ),
          // 管理
          Container(
            height: 56.w + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(
              left: 22.w,
              right: 22.w,
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            color: const Color(0xFFF6F6F6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MaterialButton(
                  onPressed: () {
                    FocusScope.of(context).requestFocus(FocusNode());

                    if (_edittingRecord) {
                      _edittingRecord = false;
                      _selectList.clear();
                      setState(() {});
                    } else {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                        builder: (context) {
                          return TagCreatePage();
                        },
                        fullscreenDialog: true,
                      ))
                          .then((value) {
                        if (value == true) {
                          _refreshController.requestRefresh();
                        }
                      });
                    }
                  },
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minWidth: 0,
                  child: Text(
                    _edittingRecord ? "取消" : "新建",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
                _dataList.length > 0
                    ? _edittingRecord
                        ? MaterialButton(
                            onPressed: _selectList.length == 0
                                ? null
                                : () {
                                    _tagDelete();
                                  },
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            minWidth: 0,
                            child: Text(
                              "删除",
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: _selectList.length == 0
                                    ? kAppConfig.appPlaceholderColor
                                    : const Color(0xFF000000),
                              ),
                            ),
                          )
                        : MaterialButton(
                            onPressed: () {
                              FocusScope.of(context).requestFocus(FocusNode());
                              _textEditingController.clear();
                              _edittingRecord = true;
                              _selectList.clear();
                              setState(() {});
                            },
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            minWidth: 0,
                            child: Text(
                              "管理",
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          )
                    : SizedBox(),
              ],
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
