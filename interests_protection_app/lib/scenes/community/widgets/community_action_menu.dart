import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:interests_protection_app/apis/community_api.dart';
import 'package:interests_protection_app/models/community_model.dart';
// import 'package:interests_protection_app/utils/utils_tool.dart';

class CommunityActionMenu extends StatefulWidget {
  final void Function(int index)? menuAction;
  final CommunityModel model;
  const CommunityActionMenu({
    Key? key,
    required this.menuAction,
    required this.model,
  }) : super(key: key);

  @override
  State<CommunityActionMenu> createState() => _CommunityActionMenuState();
}

class _CommunityActionMenuState extends State<CommunityActionMenu> {
  // List<String> _actionList = ["投诉", "赞", "评论"];
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  // 点赞
  void _likeAction() {
    SVProgressHUD.show();
    CommunityApi.like(params: {"id": widget.model.id}).then((value) {
      bool _status = (value ?? {})["status"] ?? false;
      widget.model.isLike = _status;
      if (_status) {
        widget.model.like += 1;
      } else {
        if (widget.model.like >= 1) {
          widget.model.like -= 1;
        }
      }
      setState(() {});

      _menuController.hideMenu();
      SVProgressHUD.dismiss();
    }).catchError((error) {
      SVProgressHUD.dismiss();
    });
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MaterialButton(
          onPressed: () {
            _likeAction();
          },
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minWidth: 19.w,
          height: 19.w,
          child: Image.asset(
            widget.model.isLike
                ? "images/community_heart_sel@2x.png"
                : "images/community_heart@2x.png",
            width: 19.w,
          ),
        ),
        widget.model.like > 0
            ? Container(
                margin: EdgeInsets.only(left: 4.w),
                child: Text(
                  "${widget.model.like}",
                  style: TextStyle(
                    color: const Color(0xFF808080),
                    fontSize: 12.sp,
                  ),
                ),
              )
            : SizedBox(),
      ],
    );
    // return CustomPopupMenu(
    //   controller: _menuController,
    //   child: Container(
    //     width: 32.w,
    //     height: 20.w,
    //     decoration: BoxDecoration(
    //       image: DecorationImage(
    //         image: AssetImage(
    //           "images/community_more@2x.png",
    //         ),
    //       ),
    //       borderRadius: BorderRadius.circular(5.w),
    //     ),
    //   ),
    //   menuBuilder: () {
    //     return ClipRRect(
    //       borderRadius: BorderRadius.circular(10.w),
    //       child: Container(
    //         width: 273.w,
    //         height: 38.w,
    //         decoration: BoxDecoration(
    //           color: const Color(0xFF4C4C4C),
    //           borderRadius: BorderRadius.circular(10.w),
    //         ),
    //         child: Row(
    //           children: List.generate(_actionList.length, (index) => index)
    //               .map((index) {
    //             String _text = _actionList[index];
    //             Color? _color;
    //             Color? _textColor = const Color(0xFFFFFFFF);
    //             if (index == 1) {
    //               if (widget.model.like > 0) {
    //                 _text = "${widget.model.like}";
    //               }

    //               if (widget.model.isLike) {
    //                 _color = kAppConfig.appThemeColor;
    //                 _textColor = kAppConfig.appThemeColor;
    //               }
    //             } else if (index == 2) {
    //               if (widget.model.replys.length > 0) {
    //                 _text = "${widget.model.replys.length}";
    //               }
    //             }

    //             return Expanded(
    //               child: MaterialButton(
    //                 onPressed: () {
    //                   if (index == 1) {
    //                     _likeAction();
    //                   } else {
    //                     _menuController.hideMenu();

    //                     if (widget.menuAction != null) {
    //                       widget.menuAction!(index);
    //                     }
    //                   }
    //                 },
    //                 padding: EdgeInsets.zero,
    //                 height: 38.w,
    //                 shape: RoundedRectangleBorder(
    //                   borderRadius: BorderRadius.zero,
    //                 ),
    //                 child: Row(
    //                   mainAxisAlignment: MainAxisAlignment.center,
    //                   children: [
    //                     index == 0
    //                         ? Container()
    //                         : Container(
    //                             margin: EdgeInsets.only(right: 3.w),
    //                             padding: EdgeInsets.only(top: 1.w),
    //                             child: Image.asset(
    //                               "images/${index == 1 ? 'community_like@2x.png' : 'community_comment@2x.png'}",
    //                               width: 16.w,
    //                               height: 14.w,
    //                               color: _color,
    //                             ),
    //                           ),
    //                     Text(
    //                       _text,
    //                       style: TextStyle(
    //                         color: _textColor,
    //                         fontSize: 14.sp,
    //                         fontWeight: FontWeight.normal,
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //             );
    //           }).toList(),
    //         ),
    //       ),
    //     );
    //   },
    //   pressType: PressType.singleClick,
    //   showArrow: false,
    //   verticalMargin: -(38.w + 20.w) / 2,
    //   horizontalMargin: 62.w,
    //   barrierColor: Colors.transparent,
    // );
  }
}
