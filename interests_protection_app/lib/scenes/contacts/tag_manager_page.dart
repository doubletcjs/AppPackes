import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';

class TagManagerPage extends StatefulWidget {
  final List<String> selectTabList;
  const TagManagerPage({
    super.key,
    required this.selectTabList,
  });

  @override
  State<TagManagerPage> createState() => _TagManagerPageState();
}

class _TagManagerPageState extends State<TagManagerPage> {
  TextEditingController _tagEditingController = TextEditingController();
  AppHomeController _homeController = Get.find<AppHomeController>();
  List<String> _recordTabList = [];
  List<String> _selectTabList = [];

  void _onSubmit() async {
    if (_tagEditingController.text.trim().length > 0 &&
        _recordTabList.contains(_tagEditingController.text) == false) {
      var _list = await _homeController.accountDB!.query(
        kAppTagboardTableName,
        where: "label = '${_tagEditingController.text}'",
        limit: 1,
      );

      if (_list.length == 0) {
        _homeController.accountDB!.insert(
          kAppTagboardTableName,
          {"label": _tagEditingController.text},
        ).then((value) {
          _selectTabList.add(_tagEditingController.text);
          Get.back(result: _selectTabList);
        }).catchError((error) {
          Get.back(result: _selectTabList);
        });
      } else {
        Get.back(result: _selectTabList);
      }
    } else {
      Get.back(result: _selectTabList);
    }
  }

  @override
  void initState() {
    super.initState();

    _selectTabList = List<String>.from(widget.selectTabList);
    _homeController.accountDB!.query(
      kAppTagboardTableName,
      columns: ["label"],
    ).then((value) {
      value.forEach((element) {
        String _tag = "${element['label'] ?? ''}";
        if (_tag.length > 0) {
          _recordTabList.add(_tag);
        }
      });

      if (_recordTabList.length == 0) {
        _recordTabList = List<String>.from(_selectTabList);
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _tagEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("添加标签"),
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
            onPressed: () {
              _onSubmit();
            },
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
                color: const Color(0xFF000000),
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
              Container(
                color: const Color(0xFFFFFFFF),
                height: 56.w,
                padding: EdgeInsets.only(left: 16.w, right: 16.w),
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
                          hintText: "选择或新增标签",
                          hintStyle: TextStyle(
                            color: kAppConfig.appPlaceholderColor,
                            fontSize: 15.sp,
                          ),
                        ),
                        onChanged: (value) {},
                        onSubmitted: (value) {
                          if (value == " " || value.trim().length == 0) {
                            _tagEditingController.clear();
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
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 32.w, 16.w, 14.w),
                child: Text(
                  "全部标签",
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 15.sp,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16.w, right: 16.w),
                child: Wrap(
                  spacing: 10.w,
                  runSpacing: 10.w,
                  children:
                      List.generate(_recordTabList.length, (index) => index)
                          .map((index) {
                    String _tag = _recordTabList[index];
                    return Container(
                      constraints: BoxConstraints(minHeight: 28.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(10.w),
                        border: Border.all(
                          width: 0.5.w,
                          color: _selectTabList.contains(_tag)
                              ? const Color(0xFF000000)
                              : const Color(0xFFFFFFFF),
                        ),
                      ),
                      child: MaterialButton(
                        onPressed: () {
                          if (_selectTabList.contains(_tag)) {
                            AlertVeiw.show(
                              context,
                              confirmText: "确认",
                              contentText: "是否删除该标签?",
                              cancelText: "取消",
                              confirmAction: () {
                                _selectTabList.remove(_tag);
                                setState(() {});
                              },
                            );
                          } else {
                            _selectTabList.add(_tag);
                            setState(() {});
                          }
                        },
                        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minWidth: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.w),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: 3.w,
                                bottom: 3.w,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 220.w),
                                child: Text(
                                  "$_tag",
                                  style: TextStyle(
                                    color: _selectTabList.contains(_tag)
                                        ? const Color(0xFF000000)
                                        : const Color(0xFFB3B3B3),
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
