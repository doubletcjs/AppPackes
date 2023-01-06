import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:interests_protection_app/scenes/personal/widgets/equities_content_swipe.dart';
import 'package:interests_protection_app/scenes/personal/widgets/equities_level_card.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class PersonalEquitiesPage extends StatefulWidget {
  final int level;
  const PersonalEquitiesPage({
    Key? key,
    required this.level,
  }) : super(key: key);

  @override
  State<PersonalEquitiesPage> createState() => _PersonalEquitiesPageState();
}

class _PersonalEquitiesPageState extends State<PersonalEquitiesPage> {
  final ScrollController _scrollController = ScrollController();
  int _level = 0; // 0 svip 1 vip 2 普通用户 3 未认证用户
  int _equitiesId = 0;
  int _contentIndex = 0;
  List _equitiesList = [];
  Map _equitiesGroup = {};

  final Map _backColorMap = {
    0: const Color(0xFFFFFFFF),
    1: const Color(0xFF6B3A19),
    2: const Color(0xFF42528F),
    3: const Color(0xFF636363),
  };

  final Map _backgroudColorMap = {
    0: const Color(0xFF000000),
    1: const Color(0xFFFCF3CC),
    2: const Color(0xFFC9DCF8),
    3: const Color(0xFFE4E4E4),
  };

  final Map _contentBarColorMap = {
    0: const Color(0xFFF7D8B2),
    1: const Color(0xFFFCF3CC),
    2: const Color(0xFFE6EFFA),
    3: const Color(0xFFE1E1E1),
  };

  final Map<int, Color> _equitiesTextColorMap = {
    0: const Color(0xFF541E04), //SVIP
    1: const Color(0xFF713C1C), //VIP
    2: const Color(0xFF42528F), //普通会员
    3: const Color(0xFF5A5A5A), //未实名认证
  };

  final Map _lockEquitiesId = {
    0: [], //SVIP
    1: [13, 14], //VIP
    2: [0, 1, 2, 20, 3], //普通会员
    3: [0, 1], //未实名认证
  };

  void _loadEquitiesLockState(int level) {
    if (level == 0) {
      _equitiesGroup.forEach((key, value) {
        List _list = value ?? [];
        _list.forEach((equities) {
          equities["lock"] = false;
        });
      });
    } else if (level == 1) {
      _equitiesGroup.forEach((key, value) {
        List _list = value ?? [];
        _list.forEach((equities) {
          equities["lock"] = false;

          _lockEquitiesId[level]!.forEach((element) {
            if (element == equities["id"]) {
              equities["lock"] = true;
            }
          });
        });
      });
    } else if (level == 2 || level == 3) {
      _equitiesGroup.forEach((key, value) {
        List _list = value ?? [];
        _list.forEach((equities) {
          equities["lock"] = true;

          _lockEquitiesId[level]!.forEach((element) {
            if (element == equities["id"]) {
              equities["lock"] = false;
            }
          });
        });
      });
    }
  }

  Widget _levelSwiper() {
    return SizedBox(
      height: 662.w,
      child: Swiper(
        itemBuilder: (context, index) {
          return EquitiesLevelCard(
            levelIndex: _level,
            equitiesGroup: _equitiesGroup,
            equitiesId: _equitiesId,
            equitiesIdFeedback: (id) {
              _equitiesId = id;
              _contentIndex =
                  _equitiesList.indexWhere((element) => element["id"] == id);
              setState(() {
                if (_scrollController.hasClients) {
                  Future.delayed(Duration(milliseconds: 100), () {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 10),
                      curve: Curves.linear,
                    );
                  });
                }
              });
            },
          );
        },
        viewportFraction: 0.91,
        itemCount: _backColorMap.length,
        physics: BouncingScrollPhysics(),
        loop: false,
        index: _level,
        onIndexChanged: (value) {
          _level = value;
          _loadEquitiesLockState(_level);
          setState(() {});

          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarBrightness:
                  _level == 0 ? Brightness.dark : Brightness.light,
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    rootBundle.loadString("assets/equities_group.json").then((value) {
      _equitiesGroup = json.decode(value);
      _equitiesGroup.forEach((key, value) {
        _equitiesList.addAll(value);
      });

      setState(() {});
    });
    // 0 svip 1 vip 2 普通用户 3 未认证用户
    // 用户等级
// 0：普通会员；1：VIP；2：SVIP
    _level = widget.level == 0
        ? 2
        : widget.level == 1
            ? 1
            : widget.level == 2
                ? 0
                : 3;

    Future.delayed(Duration(milliseconds: 100), () {
      // _scrollController.animateTo(
      //   _scrollController.position.maxScrollExtent,
      //   duration: Duration(milliseconds: 10),
      //   curve: Curves.linear,
      // );
      _loadEquitiesLockState(_level);

      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarBrightness: _level == 0 ? Brightness.dark : Brightness.light,
      ));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroudColorMap[_level],
      body: Stack(
        alignment: Alignment.center,
        children: _equitiesList.length == 0
            ? []
            : [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Image.asset(
                    "images/equities_top@2x.png",
                    height: 111.w + MediaQuery.of(context).padding.top,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    controller: _scrollController,
                    child: Column(
                      children: [
                        SizedBox(
                            height: 55.w + MediaQuery.of(context).padding.top),
                        _levelSwiper(),
                        SizedBox(height: 22.w),
                        EquitiesContentSwipe(
                          levelIndex: _level,
                          equities: _equitiesList,
                          contentIdFeedback: (id, index) {
                            _equitiesId = id;
                            _contentIndex = index;
                            setState(() {
                              if (_scrollController.hasClients) {
                                Future.delayed(Duration(milliseconds: 100), () {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: Duration(milliseconds: 10),
                                    curve: Curves.linear,
                                  );
                                });
                              }
                            });
                          },
                          jumpContentId: _equitiesId,
                        ),
                        Container(
                          color: const Color(0xFFFFFFFF),
                          padding: EdgeInsets.fromLTRB(
                            21.w,
                            19.w,
                            21.w,
                            19.w + MediaQuery.of(context).padding.bottom,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(width: 78.w),
                                  Positioned(
                                    bottom: 1.5.w,
                                    child: Container(
                                      width: 78.w,
                                      height: 6.w,
                                      decoration: BoxDecoration(
                                        color: _contentBarColorMap[_level],
                                        borderRadius:
                                            BorderRadius.circular(6.w / 2),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "服务内容",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      color: _equitiesTextColorMap[_level],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 14.w),
                              Text(
                                "${_equitiesList[_contentIndex]['introduction']}",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 返回按钮
                Positioned(
                  left: 5.w,
                  top: 5.w + MediaQuery.of(context).padding.top,
                  child: AppbarBack(
                    iconColor: _backColorMap[_level],
                  ),
                ),
              ],
      ),
    );
  }
}
