import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/scenes/contacts/widgets/friend_list_item.dart';
import 'package:interests_protection_app/utils/refresh_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';

class FriendSearchPage extends StatefulWidget {
  const FriendSearchPage({super.key});

  @override
  State<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  final TextEditingController _searchEditingController =
      TextEditingController();
  AppHomeController _homeController = Get.find<AppHomeController>();

  String _keyword = "";
  List<FriendModel> _dataList = [];

  void _onSearch() async {
    if (_keyword.trim().length > 0) {
      List<Map<String, Object?>> _friends =
          await _homeController.accountDB!.query(
        kAppFriendTableName,
        where: "nickname LIKE '%$_keyword%' OR remark LIKE '%$_keyword%'",
      );

      _dataList.clear();
      _friends.forEach((element) {
        Map<String, Object?> _temp = Map<String, Object?>.from(element);
        _temp["id"] = null;
        _dataList.add(FriendModel.fromJson(_temp));
      });

      setState(() {});
    } else {
      _dataList.clear();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        toolbarHeight: 64.w,
        leadingWidth: 0,
        leading: SizedBox(),
        backgroundColor: const Color(0xFFFAFAFA),
        title: Padding(
          padding: EdgeInsets.only(left: 10.w, right: 3.w),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(20.w),
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
                          autofocus: true,
                          controller: _searchEditingController,
                          style: TextStyle(
                            color: const Color(0xFF313131),
                            fontSize: 15.sp,
                          ),
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            if (value == " " || value.trim().length == 0) {
                              _searchEditingController.clear();
                              _keyword = "";
                            } else if (value.trim().length > 0) {
                              _keyword = value;
                            }

                            _onSearch();
                          },
                        ),
                      ),
                      _searchEditingController.text.length > 0
                          ? InkWell(
                              onTap: () {
                                _searchEditingController.clear();
                                _keyword = "";
                                _onSearch();
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
              MaterialButton(
                onPressed: () {
                  Get.back();
                },
                height: 40.w,
                minWidth: 0,
                padding: EdgeInsets.only(left: 18.w, right: 18.w),
                child: Text(
                  "取消",
                  style: TextStyle(
                    color: const Color(0xFF383838),
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _dataList.length == 0
          ? (_keyword.length > 0
              ? Padding(
                  padding: EdgeInsets.only(top: 65.w),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      "没有找到相关好友",
                      style: TextStyle(
                        color: const Color(0xFF808080),
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                )
              : RefreshUtilWidget.emptyDataPlaceholder())
          : ListView.builder(
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return FriendListItem(
                  friendModel: _dataList[index],
                  keyword: _keyword,
                  feedback: () {
                    try {
                      Get.toNamed(RouteNameString.chat,
                          arguments: {"fromId": _dataList[index].userId});
                    } catch (e) {}
                  },
                );
              },
              itemCount: _dataList.length,
            ),
      resizeToAvoidBottomInset: false,
    );
  }
}
