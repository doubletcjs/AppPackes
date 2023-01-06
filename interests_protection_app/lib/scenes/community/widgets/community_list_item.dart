import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/models/community_model.dart';
import 'package:interests_protection_app/scenes/community/widgets/community_action_menu.dart';
import 'package:interests_protection_app/scenes/community/widgets/community_list_comment.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/photo_view_gallery.dart';

class CommunityListItem extends StatefulWidget {
  final int index;
  final CommunityModel model;
  final bool? homePage;
  const CommunityListItem({
    super.key,
    required this.index,
    required this.model,
    this.homePage,
  });

  @override
  State<CommunityListItem> createState() => _CommunityListItemState();
}

class _CommunityListItemState extends State<CommunityListItem> {
  bool _expansionState = false;

  // 图文
  Widget _textImageContent() {
    double _maxContentWidth = 294.w;
    int _maxLines = 5;

    TextStyle _textStyle = TextStyle(
      fontSize: 14.sp,
      color: const Color(0xFF000000),
      height: 1.5,
    );

    bool _isExpansion(String text) {
      TextPainter _textPainter = TextPainter(
          maxLines: _maxLines,
          text: TextSpan(
            text: text,
            style: _textStyle,
          ),
          textDirection: TextDirection.ltr)
        ..layout(maxWidth: _maxContentWidth);
      if (_textPainter.didExceedMaxLines) {
        //判断 文本是否需要截断
        return true;
      } else {
        return false;
      }
    }

    // 图片
    Widget _imageWidget(int count) {
      if (count == 0) {
        return SizedBox();
      }

      double _itemWidth = 91.w;
      double _itemHeigth = 88.w;
      double _spacing = 11.w;
      double _runSpacing = 12.w;

      Widget _imageItem(int index) {
        return GestureDetector(
          onTap: () {
            PhotoViewGalleryPage.show(
              context,
              PhotoViewGalleryPage(
                images: widget.model.images,
                initIndex: index,
              ),
            );
          },
          child: networkImage(
            widget.model.images[index],
            Size(_itemWidth, _itemHeigth),
            BorderRadius.circular(8.w),
          ),
        );
      }

      if (count == 1) {
        _itemWidth = 150.w;
        _itemHeigth = 144.w;

        return _imageItem(0);
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: _itemWidth / _itemHeigth,
          mainAxisSpacing: _runSpacing,
          crossAxisSpacing: _spacing,
        ),
        itemBuilder: (context, index) {
          return _imageItem(index);
        },
        itemCount: count,
      );
    }

    int _imagesCount = widget.model.images.length;
    String _text = widget.model.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _isExpansion(_text)
          ? [
              // 图片
              _imageWidget(_imagesCount),
              SizedBox(height: _imagesCount > 0 ? 14.w : 0),
              // 文本
              Text(
                _text,
                maxLines: _expansionState ? null : _maxLines,
                overflow: _expansionState ? null : TextOverflow.ellipsis,
                style: _textStyle,
              ),
              SizedBox(height: 4.w),
              InkWell(
                onTap: () {
                  _expansionState = !_expansionState;
                  setState(() {});
                },
                child: Text(
                  _expansionState ? "收起" : "全文",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF5E3434),
                  ),
                ),
              ),
            ]
          : [
              // 文本
              Text(
                _text,
                style: _textStyle,
              ),
              // 图片
              SizedBox(height: _imagesCount > 0 ? 11.w : 0),
              _imageWidget(_imagesCount),
            ],
    );
  }

  Widget _likeReplyWidget() {
    if (widget.model.like == 0) {
      return SizedBox();
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (widget.homePage ?? false) == false
            ? []
            : [
                SizedBox(height: 4.w),
                Container(
                  width: 12.w,
                  margin: EdgeInsets.only(left: 18.w),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        // 四个值 top right bottom left
                        bottom: BorderSide(
                            color: const Color(0xFFF7F7F7),
// 朝上; 其他的全部透明transparent或者不设置
                            width: 6.w,
                            style: BorderStyle.solid),
                        right: BorderSide(
                            color:
                                Colors.transparent, // 朝左;  把颜色改为目标色就可以了；其他的透明
                            width: 6.w,
                            style: BorderStyle.solid),
                        left: BorderSide(
                            color: Colors.transparent, // 朝右；把颜色改为目标色就可以了；其他的透明
                            width: 6.w,
                            style: BorderStyle.solid),
                        top: BorderSide(
                            color:
                                Colors.transparent, // 朝下;  把颜色改为目标色就可以了；其他的透明
                            width: 0,
                            style: BorderStyle.solid),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 7.w, bottom: 8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10.w),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 40.w,
                        padding: EdgeInsets.only(left: 15.w),
                        child: Row(
                          children: [
                            Image.asset(
                              "images/community_liked@2x.png",
                              width: 11.w,
                              height: 9.w,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "${widget.model.like}",
                              style: TextStyle(
                                color: const Color(0xFF808080),
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // // 点赞
                      // Container(
                      //   height: 40.w,
                      //   decoration: BoxDecoration(
                      //     color: const Color(0xFFF7F7F7),
                      //     border: Border(
                      //       bottom: BorderSide(
                      //         width: 0.5.w,
                      //         color: const Color(0xFFE8E8E8),
                      //       ),
                      //     ),
                      //   ),
                      //   padding: EdgeInsets.only(left: 13.w, right: 13.w),
                      //   child: Row(
                      //     children: [
                      //       Image.asset(
                      //         "images/community_liked@2x.png",
                      //         width: 10.w,
                      //         height: 10.w,
                      //       ),
                      //       SizedBox(width: 11.w),
                      //       // Expanded(
                      //       //   child: ListView.separated(
                      //       //     shrinkWrap: true,
                      //       //     scrollDirection: Axis.horizontal,
                      //       //     itemBuilder: (context, index) {
                      //       //       return Container(
                      //       //         height: 35.w,
                      //       //         alignment: Alignment.center,
                      //       //         child: networkImage(
                      //       //           "",
                      //       //           Size(35.w, 35.w),
                      //       //           BorderRadius.circular(5.w),
                      //       //           placeholder:
                      //       //               "images/personal_placeholder@2x.png",
                      //       //         ),
                      //       //       );
                      //       //     },
                      //       //     separatorBuilder: (context, index) {
                      //       //       return SizedBox(width: 5.w);
                      //       //     },
                      //       //     itemCount: _likeList.length,
                      //       //   ),
                      //       // ),
                      //     ],
                      //   ),
                      // ),
                      // // // 回复
                      // // Container(
                      // //   color: const Color(0xFFF7F7F7),
                      // //   padding: EdgeInsets.only(left: 13.w, right: 13.w),
                      // //   child: Row(
                      // //     crossAxisAlignment: CrossAxisAlignment.start,
                      // //     children: [
                      // //       Container(
                      // //         height: 45.w,
                      // //         alignment: Alignment.center,
                      // //         child: Image.asset(
                      // //           "images/community_reply@2x.png",
                      // //           width: 10.w,
                      // //           height: 10.w,
                      // //         ),
                      // //       ),
                      // //       SizedBox(width: 11.w),
                      // //       Expanded(
                      // //         child: Column(
                      // //           children:
                      // //               List.generate(_replyList.length, (index) => index)
                      // //                   .map((index) {
                      // //             return CommunityListReplyItem(index: index);
                      // //           }).toList(),
                      // //         ),
                      // //       ),
                      // //     ],
                      // //   ),
                      // // ),
                      // SizedBox(height: 6.w),
                    ],
                  ),
                ),
              ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          InkWell(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 13.w, 16.w, 10.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 头像
                      (widget.homePage ?? false) == true
                          ? GetBuilder<AppHomeController>(
                              id: "kUpdateAccountInfo",
                              builder: (controller) {
                                return networkImage(
                                  controller.accountModel.avatar,
                                  Size(35.w, 35.w),
                                  BorderRadius.circular(5.w),
                                  placeholder:
                                      "images/personal_placeholder@2x.png",
                                  memoryData: true,
                                );
                              },
                            )
                          : networkImage(
                              kAppConfig.apiUrl + widget.model.user.avatar,
                              Size(35.w, 35.w),
                              BorderRadius.circular(5.w),
                              placeholder: "images/personal_placeholder@2x.png",
                            ),
                      SizedBox(width: 13.w),
                      Expanded(
                        child: Row(
                          children: [
                            // 名称
                            Expanded(
                              child: (widget.homePage ?? false) == true
                                  ? GetBuilder<AppHomeController>(
                                      id: "kUpdateAccountInfo",
                                      builder: (controller) {
                                        return Text(
                                          controller.accountModel.nickname,
                                          style: TextStyle(
                                            color: const Color(0xFF000000),
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    )
                                  : Text(
                                      widget.model.user.nickname,
                                      style: TextStyle(
                                        color: const Color(0xFF000000),
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            // 日期
                            Text(
                              timeLineFormat(
                                date: widget.model.createdAt,
                                chatStyle: false,
                              ),
                              style: TextStyle(
                                color: const Color(0xFFB3B3B3),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.w),
                  Row(
                    children: [
                      SizedBox(width: 35.w + 13.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _textImageContent(),
                            SizedBox(
                                height: (widget.homePage ?? false) == true
                                    ? 0
                                    : 11.w),
                            (widget.homePage ?? false) == true
                                ? SizedBox()
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 距离
                                      Text(
                                        "距离${widget.model.distance}km",
                                        style: TextStyle(
                                          color: const Color(0xFFB3B3B3),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      // 更多
                                      CommunityActionMenu(
                                        menuAction: (index) {
                                          if (index == 2) {
                                            CommunityListComment.show(context,
                                                (comment) {
                                              debugPrint("comment:$comment");
                                            });
                                          }
                                        },
                                        model: widget.model,
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // 评论、点赞
                  _likeReplyWidget(),
                ],
              ),
            ),
          ),
          widget.index == 0
              ? SizedBox()
              : Positioned(
                  top: 0,
                  left: 22.w,
                  right: 18.w,
                  child: Container(
                    color: const Color(0xFFF7F7F7),
                    height: 0.5.w,
                  ),
                ),
        ],
      ),
    );
  }
}
