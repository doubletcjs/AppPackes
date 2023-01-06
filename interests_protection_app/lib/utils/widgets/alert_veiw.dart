import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

bool _alertVeiwShow = false;

class AlertVeiw extends StatefulWidget {
  final String? cancelText;
  final String? confirmText;
  final String? contentText;
  final String? describeText;
  final Widget? contentWidget;
  final Widget? confirmWidget;
  final void Function()? cancelAction;
  final void Function()? confirmAction;
  const AlertVeiw({
    Key? key,
    this.cancelText,
    required this.confirmText,
    this.cancelAction,
    this.confirmAction,
    required this.contentText,
    this.describeText,
    this.contentWidget,
    this.confirmWidget,
  }) : super(key: key);

  @override
  State<AlertVeiw> createState() => _AlertVeiwState();

  static show(
    BuildContext context, {
    required String? confirmText,
    required String? contentText,
    String? cancelText,
    void Function()? cancelAction,
    void Function()? confirmAction,
    String? describeText,
    Widget? contentWidget,
    Widget? confirmWidget,
    bool onWillPop = true,
  }) {
    if (_alertVeiwShow) {
      return;
    }

    _alertVeiwShow = true;
    showGeneralDialog(
      context: context,
      barrierColor: const Color(0x7F000000),
      pageBuilder: (context, animation, secondaryAnimation) {
        return WillPopScope(
            child: AlertVeiw(
              confirmText: confirmText,
              contentText: contentText,
              cancelText: cancelText,
              cancelAction: cancelAction,
              confirmAction: confirmAction,
              describeText: describeText,
              contentWidget: contentWidget,
              confirmWidget: confirmWidget,
            ),
            onWillPop: () {
              return Future(() => onWillPop);
            });
      },
    );
  }
}

class _AlertVeiwState extends State<AlertVeiw> {
  @override
  void dispose() {
    _alertVeiwShow = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20.w),
          child: Container(
            width: 295.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.contentWidget ??
                    Padding(
                      padding: (widget.describeText ?? "").length > 0
                          ? EdgeInsets.fromLTRB(23.w, 24.w, 20.w, 21.w)
                          : EdgeInsets.fromLTRB(24.w, 43.w, 24.w, 30.w),
                      child: Column(
                        children: [
                          Text(
                            "${widget.contentText}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF000000),
                              fontSize: 18.sp,
                            ),
                          ),
                          (widget.describeText ?? "").length > 0
                              ? Padding(
                                  padding: EdgeInsets.only(top: 11.w),
                                  child: Text(
                                    "${widget.describeText}",
                                    style: TextStyle(
                                      color: const Color(0xFFB3B3B3),
                                      fontSize: 14.sp,
                                      height: 1.5,
                                    ),
                                  ),
                                )
                              : SizedBox(),
                        ],
                      ),
                    ),
                Padding(
                  padding: (widget.cancelText ?? "").length > 0
                      ? EdgeInsets.fromLTRB(19.w, 0, 19.w, 23.w)
                      : EdgeInsets.fromLTRB(19.w, 0, 19.w, 23.w),
                  child: Row(
                    children: [
                      // 取消
                      (widget.cancelText ?? "").length > 0
                          ? Expanded(
                              child: MaterialButton(
                                onPressed: () {
                                  Navigator.of(context).pop();

                                  if (widget.cancelAction != null) {
                                    widget.cancelAction!();
                                  }
                                },
                                padding: EdgeInsets.zero,
                                height: 44.w,
                                elevation: 0,
                                highlightElevation: 0,
                                color: const Color(0xFFFFFFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22.w),
                                  side: BorderSide(
                                    width: 1.w,
                                    color: kAppConfig.appPlaceholderColor,
                                  ),
                                ),
                                child: Text(
                                  "${widget.cancelText}",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF000000),
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(),
                      SizedBox(
                          width:
                              (widget.cancelText ?? "").length > 0 ? 17.w : 0),
                      // 确定
                      Expanded(
                        child: widget.confirmWidget ??
                            MaterialButton(
                              onPressed: () {
                                Navigator.of(context).pop();

                                if (widget.confirmAction != null) {
                                  widget.confirmAction!();
                                }
                              },
                              padding: EdgeInsets.zero,
                              height: 44.w,
                              color: kAppConfig.appThemeColor,
                              elevation: 0,
                              highlightElevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22.w),
                              ),
                              child: Text(
                                "${widget.confirmText}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFFFFFFF),
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
          ),
        ),
      ),
    );
  }
}
