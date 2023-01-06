import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/news_api.dart';
import 'package:interests_protection_app/models/news_detail_model.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';
import 'package:markdown_widget/markdown_widget.dart';

class NewsDetailPage extends StatefulWidget {
  const NewsDetailPage({Key? key}) : super(key: key);

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  String _newsId = "";
  NewsDetailModel _detailModel = NewsDetailModel.fromJson({});

  @override
  void initState() {
    super.initState();

    if (Get.arguments != null) {
      _newsId = Get.arguments["newsId"];
    }

    if (_newsId.length > 0) {
      NewsApi.index(params: {"id": _newsId}).then((value) {
        _detailModel = NewsDetailModel.fromJson(value ?? {});
        setState(() {});
      }).catchError((error) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppbarBack(),
      ),
      body: Column(
        children: _detailModel.id.length == 0
            ? []
            : [
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      top: 14.w,
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    physics: BouncingScrollPhysics(),
                    children: [
                      // 标题
                      Text(
                        "${_detailModel.title}",
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 14.w),
                      // 来源
                      Text(
                        "来自：${_detailModel.origin}",
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(height: 7.w),
                      // 日期
                      Row(
                        children: [
                          Container(
                            width: 1.5.w,
                            height: 12.w,
                            color: const Color(0xFFEDD5D5),
                            margin: EdgeInsets.only(right: 5.w),
                          ),
                          Text(
                            "${DateUtil.formatDateStr(_detailModel.updatedAt, format: "yyyy-MM-dd HH:mm")}",
                            style: TextStyle(
                              color: const Color(0xFFB3B3B3),
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 11.w),
                      ...MarkdownGenerator(
                        data: _detailModel.content,
                        styleConfig: StyleConfig(
                          imgBuilder: (url, attributes) {
                            // return Image.network(url);
                            return networkImage(url, null, BorderRadius.zero);
                          },
                        ),
                      ).widgets!,
                    ],
                  ),
                ),
                // Container(
                //   width: MediaQuery.of(context).size.width,
                //   height: 55.w + MediaQuery.of(context).padding.bottom,
                //   padding: EdgeInsets.only(
                //     bottom: MediaQuery.of(context).padding.bottom,
                //   ),
                //   color: const Color(0xFFFFFFFF),
                // ),
              ],
      ),
    );
  }
}
