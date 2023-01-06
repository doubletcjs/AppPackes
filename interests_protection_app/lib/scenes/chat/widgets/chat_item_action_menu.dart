import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatItemActionMenu extends StatefulWidget {
  final Widget child;
  final void Function(int index)? menuAction;
  final bool ignoring;
  final List<String>? customActionList;
  const ChatItemActionMenu({
    super.key,
    required this.child,
    required this.menuAction,
    required this.ignoring,
    this.customActionList,
  });

  @override
  State<ChatItemActionMenu> createState() => _ChatItemActionMenuState();
}

class _ChatItemActionMenuState extends State<ChatItemActionMenu> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();
  List<String> _actionList = ["复制", "删除"];

  @override
  void initState() {
    super.initState();

    _actionList = widget.customActionList ?? ["复制", "删除"];
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.ignoring,
      child: CustomPopupMenu(
        child: widget.child,
        controller: _menuController,
        menuBuilder: () {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: Container(
              width: 60.w * _actionList.length,
              height: 38.w,
              decoration: BoxDecoration(
                color: const Color(0xFF4C4C4C),
                borderRadius: BorderRadius.circular(10.w),
              ),
              child: Row(
                children: List.generate(_actionList.length, (index) => index)
                    .map((index) {
                  String _text = _actionList[index];
                  Color? _textColor = const Color(0xFFFFFFFF);
                  return Expanded(
                    child: MaterialButton(
                      onPressed: () {
                        _menuController.hideMenu();

                        if (widget.menuAction != null) {
                          widget.menuAction!(index);
                        }
                      },
                      padding: EdgeInsets.zero,
                      height: 38.w,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      elevation: 0,
                      focusElevation: 0,
                      highlightElevation: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          index == 0
                              ? SizedBox()
                              : Container(
                                  height: 20.w,
                                  width: 0.5.w,
                                  color: const Color(0xFFFFFFFF),
                                ),
                          Expanded(
                            child: Text(
                              _text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.normal,
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
          );
        },
        pressType: PressType.longPress,
        showArrow: true,
        position: PreferredPosition.top,
        verticalMargin: -2.w,
        barrierColor: Colors.transparent,
      ),
    );
  }
}
