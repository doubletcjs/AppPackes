import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/news_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/scenes/news/news_list_page.dart';
import 'package:interests_protection_app/scenes/tickets/tickets_publish_page.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class NewsTabPage extends StatefulWidget {
  NewsTabPage({Key? key}) : super(key: key);

  @override
  State<NewsTabPage> createState() => _NewsTabPageState();
}

class _NewsTabPageState extends State<NewsTabPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late PageController _pageController = PageController();
  late TabController _tabController;
  List<String> _titleItemList = ["国际", "定位"];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _titleItemList.length, vsync: this);

    Future.delayed(Duration(milliseconds: 300), () {
      NewsApi.location(
        params: {
          "page": 1,
          "pagesize": 1,
        },
        isShowErr: false,
      ).then((value) {
        String _country = value["country"] ?? "";
        if (_country.length > 0) {
          if (_titleItemList[1] != _country && mounted) {
            _titleItemList[1] = _country;
            setState(() {});
          }
        }
      }).catchError((error) {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppConfig.appThemeColor,
        leadingWidth: 13.w + 400.w,
        // logo
        leading: Container(
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.only(left: 13.w),
          child: Image.asset(
            "images/news_logo@2x.png",
            height: 28.w,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 搜索框
                  Expanded(
                    // child: Container(
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFFC4322F),
                    //     borderRadius: BorderRadius.circular(33.w / 2),
                    //   ),
                    //   height: 33.w,
                    //   alignment: Alignment.center,
                    //   child: MaterialButton(
                    //     onPressed: () {},
                    //     padding: EdgeInsets.only(left: 14.w, right: 14.w),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(33.w / 2),
                    //     ),
                    //     height: 33.w,
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //       children: [
                    //         Row(
                    //           children: [
                    //             Image.asset(
                    //               "images/news_bar_search@2x.png",
                    //               width: 17.w,
                    //               height: 17.w,
                    //             ),
                    //             SizedBox(width: 4.w),
                    //             Text(
                    //               "搜索",
                    //               style: TextStyle(
                    //                 color: const Color(0xFFE29997),
                    //                 fontSize: 15.sp,
                    //                 fontWeight: FontWeight.normal,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //         Row(
                    //           children: [
                    //             Image.asset(
                    //               "images/news_weather@2x.png",
                    //               width: 17.w,
                    //               height: 17.w,
                    //             ),
                    //             SizedBox(width: 4.w),
                    //             Text(
                    //               "25°C",
                    //               style: TextStyle(
                    //                 color: const Color(0xFFFFFFFF),
                    //                 fontSize: 10.sp,
                    //                 fontWeight: FontWeight.normal,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    child: SizedBox(),
                  ),
                  // 线索征集
                  MaterialButton(
                    onPressed: () {
                      Get.find<AppHomeController>().onTabNotify(0,
                          (index, xpin) {
                        if (Get.find<AppHomeController>().xpinMode == false) {
                          Get.to(TicketsPublishPage());
                        }
                      });
                    },
                    height: 33.w,
                    child: Text(
                      "线索征集",
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: [
            // 资讯类型
            Container(
              height: 48.w,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                border: Border(
                  bottom: BorderSide(
                    width: 1.w,
                    color: const Color(0xFFF7F7F7),
                  ),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TabBar(
                    controller: _tabController,
                    unselectedLabelStyle: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelColor: const Color(0xFF000000),
                    labelColor: kAppConfig.appThemeColor,
                    indicatorColor: kAppConfig.appThemeColor,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 3.w,
                    isScrollable: true,
                    padding: EdgeInsets.only(top: 8.w),
                    tabs: _titleItemList.map((e) {
                      return Tab(text: e);
                    }).toList(),
                    onTap: (value) {
                      _pageController.jumpToPage(value);
                    },
                  ),
                  Positioned(
                    left: 15.w,
                    child: Text(
                      "${Get.find<AppHomeController>().appVersion}",
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 资讯列表
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return NewsListPage(
                    tag: index,
                    countrySwitch: (country) {
                      if (_titleItemList[1] != country) {
                        _titleItemList[1] = country;
                        setState(() {});
                      }
                    },
                  );
                },
                itemCount: _titleItemList.length,
                onPageChanged: (value) {
                  _tabController.animateTo(value);
                },
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
