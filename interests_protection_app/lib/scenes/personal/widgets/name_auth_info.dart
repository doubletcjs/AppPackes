import 'package:auto_size_text/auto_size_text.dart';
import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class NameAuthInfo extends StatefulWidget {
  final void Function(bool fill)? fillFeedback;
  final void Function()? nextStepAction;
  final void Function(
          String name, String identity, String startDate, String endDate)?
      infoFeedback;
  const NameAuthInfo({
    Key? key,
    required this.fillFeedback,
    required this.nextStepAction,
    required this.infoFeedback,
  }) : super(key: key);

  @override
  State<NameAuthInfo> createState() => _NameAuthInfoState();
}

class _NameAuthInfoState extends State<NameAuthInfo> {
  TextEditingController _nameEditingController = TextEditingController();
  TextEditingController _identityEditingController = TextEditingController();
  FocusNode _nameFocusNode = FocusNode();
  FocusNode _identityFocusNode = FocusNode();
  bool _infoFill = false;

  String _startDate = "";
  String _endDate = "";

  // 校验
  void _checkInfoFill() {
    if (_nameEditingController.text.trim().length > 0 &&
        _identityEditingController.text.trim().length > 0 &&
        _startDate.length > 0 &&
        _endDate.length > 0) {
      if (_identityEditingController.text.length == 18) {
        _infoFill = true;
      } else {
        _infoFill = false;
      }
    } else {
      _infoFill = false;
    }

    setState(() {});

    if (widget.fillFeedback != null) {
      widget.fillFeedback!(_infoFill);
    }

    if (widget.infoFeedback != null) {
      widget.infoFeedback!(
        _nameEditingController.text,
        _identityEditingController.text,
        _startDate,
        _endDate,
      );
    }
  }

  // 日期选择
  void _datePicker(int type) {
    if (type == 1 && _startDate.length == 0) {
      utilsToast(msg: "请先选择开始日期");

      _datePicker(0);
      return;
    }

    String _date = "";
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: const Color(0xFFFFFFFF),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MaterialButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minWidth: 60.w,
                        height: 44.w,
                        child: Text(
                          "取消",
                          style: TextStyle(
                            color: kAppConfig.appPlaceholderColor,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                      MaterialButton(
                        onPressed: () {
                          if (type == 0) {
                            _startDate = _date;
                            _endDate = "";
                          } else {
                            _endDate = _date;
                          }

                          _checkInfoFill();
                          Navigator.of(context).pop();
                        },
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minWidth: 60.w,
                        height: 44.w,
                        child: Text(
                          "确定",
                          style: TextStyle(
                            color: const Color(0xFF0000000),
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFFFFFFFF),
                  height: 216.w,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    minimumDate: type == 1
                        ? DateUtil.getDateTime(_startDate.replaceAll(".", "-"))
                        : null,
                    initialDateTime: type == 1
                        ? DateUtil.getDateTime(_startDate.replaceAll(".", "-"))
                        : null,
                    onDateTimeChanged: (dateTime) {
                      _date =
                          DateUtil.formatDate(dateTime, format: "yyyy.MM.dd");
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameEditingController.dispose();
    _identityEditingController.dispose();
    _nameFocusNode.dispose();
    _identityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(25.w, 16.w, 25.w, 0),
        child: Column(
          children: [
            Column(
              children: [
                Container(
                  height: 48.w,
                  padding: EdgeInsets.only(left: 21.w, right: 21.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(48.w / 2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "真实姓名：",
                        style: TextStyle(
                          color: const Color(0xFF808080),
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: TextField(
                          controller: _nameEditingController,
                          focusNode: _nameFocusNode,
                          style: TextStyle(
                            color: const Color(0xFF000000),
                            fontSize: 18.sp,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                          ),
                          onSubmitted: (value) {
                            if (value.trim().length > 0) {
                              _identityFocusNode.requestFocus();
                            }
                          },
                          onChanged: (value) {
                            _checkInfoFill();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 19),
                Container(
                  height: 48.w,
                  padding: EdgeInsets.only(left: 21.w, right: 21.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(48.w / 2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "身份证号：",
                        style: TextStyle(
                          color: const Color(0xFF808080),
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: TextField(
                          controller: _identityEditingController,
                          focusNode: _identityFocusNode,
                          style: TextStyle(
                            color: const Color(0xFF000000),
                            fontSize: 18.sp,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp("[0-9_X]")),
                            LengthLimitingTextInputFormatter(18)
                          ],
                          onSubmitted: (value) {
                            if (value.trim().length > 0 &&
                                _nameEditingController.text.trim().length > 0) {
                            } else {
                              _identityFocusNode.requestFocus();
                            }
                          },
                          onChanged: (value) {
                            _checkInfoFill();
                          },
                        ),
                      ),
                      _identityEditingController.text.trim().length > 0
                          ? InkWell(
                              onTap: () {
                                _identityEditingController.clear();
                                _checkInfoFill();
                              },
                              child: Image.asset(
                                "images/login_clean@2x.png",
                                width: 16.w,
                                height: 16.w,
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                ),
                SizedBox(height: 19),
                Container(
                  height: 48.w,
                  padding: EdgeInsets.only(left: 21.w, right: 10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(48.w / 2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "有效日期：",
                        style: TextStyle(
                          color: const Color(0xFF808080),
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: MaterialButton(
                          onPressed: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            _datePicker(0);
                          },
                          height: 26.w,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          child: AutoSizeText(
                            "$_startDate",
                            minFontSize: 12,
                            style: TextStyle(
                              color: const Color(0xFF030101),
                              fontSize: 15.sp,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        "至",
                        style: TextStyle(
                          color: const Color(0xFF808080),
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: MaterialButton(
                          onPressed: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            _datePicker(1);
                          },
                          height: 26.w,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          child: AutoSizeText(
                            "$_endDate",
                            minFontSize: 12,
                            style: TextStyle(
                              color: const Color(0xFF030101),
                              fontSize: 15.sp,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.w),
            Padding(
              padding: EdgeInsets.only(left: 21.w),
              child: Row(
                children: [
                  Image.asset(
                    "images/identity_tip@2x.png",
                    width: 10.w,
                    height: 10.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      "用于身份实名核验，资料将被加密保护。",
                      style: TextStyle(
                        color: const Color(0xFFB3B3B3),
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 116.w),
            Container(
              height: 48.w,
              decoration: BoxDecoration(
                color: _infoFill
                    ? kAppConfig.appThemeColor
                    : const Color(0xFFEDD5D5),
                borderRadius: BorderRadius.circular(40.w),
              ),
              margin: EdgeInsets.only(left: 29.w, right: 29.w),
              child: Row(
                children: [
                  Expanded(
                    child: MaterialButton(
                      onPressed: _infoFill
                          ? () {
                              if (isIdCard(_identityEditingController.text) ==
                                  false) {
                                utilsToast(msg: "请输入合法的身份证号码！");
                              } else {
                                if (widget.nextStepAction != null) {
                                  widget.nextStepAction!();
                                }
                              }
                            }
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40.w),
                      ),
                      height: 48.w,
                      child: Text(
                        "下一步",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFFFFFFF),
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
