import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/community_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/controllers/personal_data_controller.dart';
import 'package:interests_protection_app/models/community_model.dart';
import 'package:interests_protection_app/scenes/community/community_home_page.dart';
import 'package:interests_protection_app/scenes/community/community_publish_page.dart';
import 'package:interests_protection_app/scenes/community/widgets/community_list_item.dart';

import 'package:interests_protection_app/utils/refresh_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:permission_handler/permission_handler.dart';

class CommunityTabPage extends StatefulWidget {
  CommunityTabPage({Key? key}) : super(key: key);

  @override
  State<CommunityTabPage> createState() => _CommunityTabPageState();
}

class _CommunityTabPageState extends State<CommunityTabPage>
    with AutomaticKeepAliveClientMixin {
  RefreshUtilController _refreshController =
      RefreshUtilController(initialRefresh: true);
  bool _locationOpen = false;
  PersonalDataController _personalDataController =
      Get.find<PersonalDataController>();
  late StreamSubscription? _stateStreamSubscription;
  List<CommunityModel> _dataList = [];
  List<String> _topicList = [
    "医疗",
    "休闲",
    "餐饮",
    "游玩",
    "酒店",
  ];

  // 热门话题
  Widget hotTopicBar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kAppConfig.appThemeColor,
      ),
      child: Column(
        children: [
          Container(
            height: 87.w,
            alignment: Alignment.center,
            margin: EdgeInsets.only(bottom: 0.5.w),
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(left: 25.w, right: 25.w),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {},
                  child: Column(
                    children: [
                      SizedBox(height: 16.w),
                      networkImage(
                        "",
                        Size(40.w, 40.w),
                        BorderRadius.circular(40.w / 2),
                      ),
                      SizedBox(height: 5.w),
                      Text(
                        _topicList[index],
                        style: TextStyle(
                          color: const Color(0xFFFFFFFF),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return SizedBox(width: 32.w);
              },
              itemCount: _topicList.length,
            ),
          ),
          Container(
            height: 18.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.w),
                topRight: Radius.circular(20.w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 开启定位
  void _openLocation() {
    void _setting(bool open) {
      StorageUtils.sharedPreferences.then((value) {
        _personalDataController.statusList[0] = open;
        value.setBool(kAppLocationStatus, open);
        _personalDataController.update();

        if (open) {
          SVProgressHUD.show();
          _personalDataController.reportLocation(
            feedBack: () {
              _refreshController.requestRefresh();
              SVProgressHUD.dismiss();
            },
          );
          _personalDataController.setReportMode(
              isRescue: Get.find<AppHomeController>().accountModel.rescue == 1);
        } else {
          _personalDataController.reportCancel();
          _personalDataController.update();
          _refreshController.requestRefresh();
        }
      });
    }

    void _open() async {
      bool _serviceEnabled =
          await Permission.location.serviceStatus == ServiceStatus.enabled;
      PermissionStatus _permissionStatus = await Permission.notification.status;

      if (_serviceEnabled == false ||
          _permissionStatus == PermissionStatus.permanentlyDenied) {
        utilsToast(msg: "请先打开手机定位");
        Future.delayed(Duration(seconds: 1), () {
          openAppSettings();
        });
        return;
      }

      if (_permissionStatus == PermissionStatus.granted) {
        _setting(true);
      } else {
        await Permission.notification.request().then((value) {
          if (value == PermissionStatus.granted) {
            _setting(true);
          }
        });
      }
    }

    _open();
  }

  // 刷新列表
  void _refreshAction() {
    if (_personalDataController.statusList[0] == true) {
      if (_personalDataController.localPosition == null) {
        _dataList.clear();
        _locationOpen = true;
        _refreshController.refreshCompleted();

        setState(() {});

        if (_dataList.length == 0) {
          _refreshController.status = RefreshUtilStatus.emptyData;
        }
      } else {
        CommunityApi.index(params: {
          "lon": _personalDataController.localPosition?.longitude,
          "lat": _personalDataController.localPosition?.latitude,
          "last_id": "",
          // "distance": 100,
        }).then((value) {
          _dataList.clear();
          _locationOpen = true;
          List _list = value ?? [];
          _list.forEach((element) {
            _dataList.add(CommunityModel.fromJson(element));
          });

          _refreshController.loadNoData();
          _refreshController.refreshCompleted();
          setState(() {});

          if (_dataList.length == 0) {
            _refreshController.status = RefreshUtilStatus.emptyData;
          }
        }).catchError((error) {
          _refreshController.refreshFailed();
          setState(() {});

          if (error is Map && error["code"] == -998) {
            _refreshController.status = RefreshUtilStatus.networkFailure;
          } else if (_dataList.length == 0) {
            _refreshController.status = RefreshUtilStatus.emptyData;
          }
        });
      }
    } else {
      _locationOpen = false;
      setState(() {
        _refreshController.refreshCompleted();
        _refreshController.status = RefreshUtilStatus.locationFailure;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _stateStreamSubscription =
        _personalDataController.stateHandler.stream.listen((event) {
      if (mounted) {
        _refreshController.requestRefresh();
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _refreshController.dispose();
    _stateStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppConfig.appThemeColor,
        titleSpacing: 0,
        elevation: 0,
        leadingWidth: 0,
        leading: SizedBox(),
        title: Container(
          padding: EdgeInsets.only(left: 16.w, right: 20.w),
          color: kAppConfig.appThemeColor,
          height: 45.w,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Positioned(
              //   left: 0,
              //   child: _locationOpen == false ||
              //           _personalDataController.localPosition == null
              //       ? SizedBox()
              //       : Text(
              //           "东经 ${_personalDataController.localPosition?.longitude.toStringAsFixed(8)}   北纬 ${_personalDataController.localPosition?.latitude.toStringAsFixed(8)}",
              //           style: TextStyle(
              //             color: const Color(0xFFFFFFFF),
              //             fontSize: 12.sp,
              //             fontWeight: FontWeight.normal,
              //           ),
              //         ),
              // ),
              Positioned(
                right: 0,
                child: Row(
                  children: [
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28.w / 2),
                        image: DecorationImage(
                          image: AssetImage("images/community_mine@2x.png"),
                        ),
                      ),
                      child: MaterialButton(
                        onPressed: () {
                          Get.to(CommunityHomePage());
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.w / 2),
                        ),
                      ),
                    ),
                    _locationOpen == false
                        ? SizedBox()
                        : Container(
                            width: 28.w,
                            height: 28.w,
                            margin: EdgeInsets.only(left: 20.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28.w / 2),
                              image: DecorationImage(
                                image: AssetImage(
                                    "images/community_publish@2x.png"),
                              ),
                            ),
                            child: MaterialButton(
                              onPressed: () {
                                Get.to(CommunityPublishPage())?.then((value) {
                                  if (value == true) {
                                    _refreshController.requestRefresh();
                                  }
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28.w / 2),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshUtilWidget(
        refreshController: _refreshController,
        onRefresh: () {
          _refreshAction();
        },
        onLoadMore: () {},
        statusFeedback:
            _refreshController.status == RefreshUtilStatus.locationFailure
                ? () {
                    _openLocation();
                  }
                : null,
        child: ListView.builder(
          physics: BouncingScrollPhysics(),
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          padding: EdgeInsets.only(bottom: 15.w),
          itemBuilder: (context, index) {
            return CommunityListItem(index: index, model: _dataList[index]);
          },
          itemCount: _dataList.length,
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
