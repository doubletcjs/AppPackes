import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommunityListComment extends StatefulWidget {
  final void Function(String comment)? commentAction;
  const CommunityListComment({super.key, required this.commentAction});

  @override
  State<CommunityListComment> createState() => _CommunityListCommentState();

  static show(
    BuildContext context,
    final void Function(String comment)? commentAction,
  ) {
    showGeneralDialog(
      context: context,
      barrierColor: const Color(0x1E000000),
      pageBuilder: (context, animation, secondaryAnimation) {
        return CommunityListComment(commentAction: commentAction);
      },
    );
  }
}

class _CommunityListCommentState extends State<CommunityListComment> {
  final TextEditingController _commentEditingController =
      TextEditingController();

  @override
  void dispose() {
    _commentEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(minHeight: 60.w),
                color: const Color(0xFFF6F6F6),
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                padding: EdgeInsets.fromLTRB(
                  10.w,
                  10.w,
                  10.w,
                  10.w + MediaQuery.of(context).padding.bottom,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(10.w),
                  ),
                  constraints: BoxConstraints(minHeight: 40.w),
                  padding: EdgeInsets.only(left: 11.w, right: 11.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          minLines: 1,
                          maxLines: 5,
                          controller: _commentEditingController,
                          style: TextStyle(
                            color: const Color(0xFF313131),
                            fontSize: 15.sp,
                          ),
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (value) {
                            if (value.trim().length > 0) {
                              Navigator.of(context).pop();

                              if (widget.commentAction != null) {
                                widget.commentAction!(value);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
