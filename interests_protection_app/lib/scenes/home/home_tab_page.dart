import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/controllers/personal_data_controller.dart';
import 'package:interests_protection_app/scenes/community/community_tab_page.dart';
import 'package:interests_protection_app/scenes/contacts/contacts_tab_page.dart';
import 'package:interests_protection_app/scenes/news/news_tab_page.dart';
import 'package:interests_protection_app/scenes/personal/personal_tab_page.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class HomeTabPage extends StatefulWidget {
  HomeTabPage({Key? key}) : super(key: key);

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> with WidgetsBindingObserver {
  final AppHomeController _homeController = Get.find<AppHomeController>();
  final PageController _pageController = PageController();
  GlobalKey<ConvexAppBarState> _appBarKey = GlobalKey<ConvexAppBarState>();
  final List<Widget> _pageList = [
    NewsTabPage(),
    CommunityTabPage(),
    Container(),
    ContactsTabPage(),
    PersonalTabPage(),
  ];
  final List<String> _tabIconList = [
    "images/tab_home@2x.png",
    "images/tab_community@2x.png",
    "",
    "images/tab_contacts@2x.png",
    "images/tab_personal@2x.png",
  ];
  final List<String> _tabTitleList = [
    "预警",
    "社区",
    "",
    "通讯",
    "我的",
  ];

  @override
  void initState() {
    try {
      Get.find<PersonalDataController>().launchMessageDestroy();
    } catch (e) {}

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: _pageList,
          ),
          Positioned(
            top: 0,
            child: GetBuilder<AppHomeController>(
              id: "kSseStateUpdate",
              builder: (controller) {
                return Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    child: Container(
                      height: 44.w,
                      width: 44.w,
                      child: Center(
                        child: Text(
                          controller.sseState == 2
                              ? "已断开"
                              : controller.sseState == -1
                                  ? "未连接"
                                  : controller.sseState == 0
                                      ? "连接中"
                                      : "",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: (controller.sseState == 2
                                    ? Colors.blue
                                    : controller.sseState == 0
                                        ? Colors.yellow
                                        : controller.sseState == -1
                                            ? Colors.yellow
                                            : Colors.grey)
                                .withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: StyleProvider(
        style: _CustomStyle(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GetBuilder<AppHomeController>(
              id: "kBadgeNumber",
              builder: (controller) {
                return ConvexAppBar.badge(
                  {
                    0: "",
                    1: "",
                    2: "",
                    3: controller.badgeNumber,
                    4: "",
                  },
                  badgeMargin: EdgeInsets.only(
                    bottom: 32.w,
                    left: 26.w,
                  ),
                  key: _appBarKey,
                  items: [
                    TabItem(
                      icon: Image.asset(_tabIconList[0]),
                      activeIcon: Image.asset(
                        _tabIconList[0].replaceAll("@2x", "_sel@2x"),
                      ),
                      title: _tabTitleList[0],
                    ),
                    TabItem(
                      icon: Image.asset(_tabIconList[1]),
                      activeIcon: Image.asset(
                        _tabIconList[1].replaceAll("@2x", "_sel@2x"),
                      ),
                      title: _tabTitleList[1],
                    ),
                    TabItem(
                      icon: Container(
                        alignment: Alignment.topCenter,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(60.w),
                        ),
                        child: Image.asset(
                          "images/tab_assistant@2x.png",
                          width: 46.w,
                          height: 46.w,
                        ),
                      ),
                    ),
                    TabItem(
                      icon: Image.asset(_tabIconList[3]),
                      activeIcon: Image.asset(
                        _tabIconList[3].replaceAll("@2x", "_sel@2x"),
                      ),
                      title: _tabTitleList[3],
                    ),
                    TabItem(
                      icon: Image.asset(_tabIconList[4]),
                      activeIcon: Image.asset(
                        _tabIconList[4].replaceAll("@2x", "_sel@2x"),
                      ),
                      title: _tabTitleList[4],
                    ),
                  ],
                  style: TabStyle.fixedCircle,
                  height: 50.w,
                  color: const Color(0xFFA6A6A6),
                  activeColor: kAppConfig.appThemeColor,
                  backgroundColor: const Color(0xFFFFFFFF),
                  elevation: 0,
                  top: -14.w,
                  curveSize: 110.w,
                  onTap: (index) {
                    _pageController.jumpToPage(index);
                  },
                  onTabNotify: (index) {
                    if (index > 0) {
                      _homeController.onTabNotify(index, (blockIndex, xpin) {
                        _pageController.jumpToPage(blockIndex);
                        _appBarKey.currentState?.animateTo(blockIndex);
                      });

                      return false;
                    }

                    return true;
                  },
                );
              },
            ),
            Positioned(
              bottom: 2,
              child: Container(
                color: const Color(0xFFFFFFFF),
                width: 46.w,
                height: 5.w,
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}

/// CLASS STYLE
class _CustomStyle extends StyleHook {
  @override
  double get activeIconSize => 21.w;

  @override
  double get activeIconMargin => 4.w;

  @override
  double get iconSize => 21.w;

  @override
  TextStyle textStyle(Color color, String? fontFamily) {
    return TextStyle(
      fontSize: 11.sp,
      color: color,
      height: 1.3,
    );
  }
}
