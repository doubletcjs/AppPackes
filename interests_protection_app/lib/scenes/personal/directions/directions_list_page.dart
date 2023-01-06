import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/scenes/personal/directions/directions_detail_page.dart';
import 'package:interests_protection_app/scenes/tickets/tickets_publish_page.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class DirectionsListPage extends StatefulWidget {
  const DirectionsListPage({super.key});

  @override
  State<DirectionsListPage> createState() => _DirectionsListPageState();
}

class _DirectionsListPageState extends State<DirectionsListPage> {
  String _homePage = "http://192.168.3.107:8181/help";
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        leading: AppbarBack(),
        title: Text(
          "APP使用说明",
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: Uri.parse(_homePage),
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onLoadStart: (controller, url) {
          if (url.toString() != _homePage) {
            _webViewController?.stopLoading();
            Get.to(DirectionsDetailPage(detailUrl: url.toString()))
                ?.then((value) async {
              if (await _webViewController?.canGoBack() == true) {
                _webViewController?.goBack();
              }
            });
          }
        },
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        height: 56.w + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        color: const Color(0xFFFFFFFF),
        child: MaterialButton(
          onPressed: () {
            if (Get.find<AppHomeController>().accountModel.level == 0) {
              Get.to(
                TicketsPublishPage(),
                transition: Transition.downToUp,
                popGesture: false,
                fullscreenDialog: true,
              );
            } else {
              Get.toNamed(RouteNameString.customer);
            }
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "images/customer@2x.png",
                width: 15.w,
                height: 15.w,
              ),
              SizedBox(width: 10.w),
              Text(
                "在线咨询",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF545454),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
