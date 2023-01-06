import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/community_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/models/community_model.dart';
import 'package:interests_protection_app/models/list_page_model.dart';
import 'package:interests_protection_app/scenes/community/widgets/community_list_item.dart';
import 'package:interests_protection_app/utils/refresh_util.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class CommunityHomePage extends StatefulWidget {
  const CommunityHomePage({super.key});

  @override
  State<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage> {
  RefreshUtilController _refreshController =
      RefreshUtilController(initialRefresh: true);

  int _page = 1;
  int _pagesize = 10;
  List<CommunityModel> _dataList = [];

  void _refreshData() {
    _page = 1;
    _refreshController.resetNoData();
    setState(() {});

    _requestCommunity();
  }

  void _loadMoreData() {
    _page += 1;
    setState(() {});

    _requestCommunity();
  }

  void _requestCommunity() {
    CommunityApi.meIndex(params: {
      "page": _page,
      "pagesize": _pagesize,
    }).then((value) {
      ListPageModel _pageModel = ListPageModel.fromJson(value["page"] ?? {});
      List _list = value["items"] ?? [];
      List<CommunityModel> _postList = [];
      _list.forEach((element) {
        CommunityModel _listModel = CommunityModel.fromJson(element ?? {});
        if (_listModel.id.length > 0) {
          _postList.add(_listModel);
        }
      });

      if (_page > 1) {
        _dataList.addAll(_postList);
      } else {
        _dataList.clear();
        _dataList.addAll(_postList);
        _refreshController.refreshCompleted();
      }

      if (_pageModel.count == _pageModel.curpage) {
        _refreshController.loadNoData();
      }

      if (_dataList.length == 0) {
        _refreshController.status = RefreshUtilStatus.emptyData;
      }

      setState(() {});
    }).catchError((error) {
      if (_page > 1) {
        _refreshController.loadFailed();
        _page -= 1;
      } else {
        _refreshController.refreshFailed();
      }

      if (error is Map && error["code"] == -998) {
        _refreshController.status = RefreshUtilStatus.networkFailure;
      } else if (_dataList.length == 0) {
        _refreshController.status = RefreshUtilStatus.emptyData;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppConfig.appThemeColor,
        titleSpacing: 0,
        elevation: 0,
        toolbarHeight: 0,
        leadingWidth: 0,
        leading: SizedBox(),
      ),
      body: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GetBuilder<AppHomeController>(
                id: "kUpdateAccountInfo",
                builder: (controller) {
                  return Container(
                    height: 103.w,
                    color: kAppConfig.appThemeColor,
                    margin: EdgeInsets.only(bottom: 0.5.w),
                    padding: EdgeInsets.only(left: 6.w, right: 16.w),
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 86.w,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppbarBack(iconColor: const Color(0xFFFFFFFF)),
                          Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: 200.w),
                                    child: Text(
                                      "${controller.accountModel.nickname}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFFFFFFFF),
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4.w),
                                  Row(
                                    children: [
                                      Image.asset(
                                        "images/community_location@2x.png",
                                        width: 12.w,
                                        height: 12.w,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        "${controller.accountModel.location}",
                                        style: TextStyle(
                                          color: const Color(0xFFFFA1A1),
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(width: 9.w),
                              networkImage(
                                controller.accountModel.avatar,
                                Size(48.w, 48.w),
                                BorderRadius.circular(5.w),
                                placeholder:
                                    "images/personal_placeholder@2x.png",
                                memoryData: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 17.w,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.w),
                              topRight: Radius.circular(20.w),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: RefreshUtilWidget(
              refreshController: _refreshController,
              onRefresh: _refreshData,
              onLoadMore: _dataList.length < _pagesize ? null : _loadMoreData,
              child: ListView(
                physics: BouncingScrollPhysics(),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  // 列表内容
                  ...List.generate(_dataList.length, (index) => index)
                      .map((index) {
                    return CommunityListItem(
                      index: index,
                      model: _dataList[index],
                      homePage: true,
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
