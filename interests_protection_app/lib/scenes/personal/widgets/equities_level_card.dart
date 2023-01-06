import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class EquitiesLevelCard extends StatelessWidget {
  final int levelIndex;
  final Map equitiesGroup;
  final int equitiesId;
  final void Function(int id)? equitiesIdFeedback;
  EquitiesLevelCard({
    Key? key,
    required this.levelIndex,
    required this.equitiesGroup,
    this.equitiesIdFeedback,
    required this.equitiesId,
  }) : super(key: key);
// 用户等级
// 0：普通会员；1：VIP；2：SVIP

  final List<String> _equitiesList = [
    "images/equities_svip@2x.png", //SVIP
    "images/equities_vip@2x.png", //VIP
    "images/equities_default@2x.png", //普通会员
    "images/equities_normal@2x.png", // 未实名认证
  ];

  final Map _textColorMap = {
    0: const Color(0xFF703D1E), //SVIP
    1: const Color(0xFF703D1E), //VIP
    2: const Color(0xFF42528F), //普通会员
    3: const Color(0xFF5A5A5A), //未实名认证
  };

  final Map<int, Color> _equitiesTextColorMap = {
    0: const Color(0xFF541E04), //SVIP
    1: const Color(0xFF713C1C), //VIP
    2: const Color(0xFF42528F), //普通会员
    3: const Color(0xFF5A5A5A), //未实名认证
  };

  final Map<int, Color> _freeTextColorMap = {
    0: const Color(0xFF541E04), //SVIP
    1: const Color(0xFFFF8D1A), //VIP
    2: const Color(0xFF42528F), //普通会员
    3: const Color(0xFFA1A1A1), //未实名认证
  };

  final Map _gradientColorMap = {
    0: [const Color(0xFFE3B388), const Color(0xFFF7D8B2)], //SVIP
    1: [const Color(0xFFEBD6A2), const Color(0xFFF0DFB4)], //VIP
    2: [const Color(0xFFABC5ED), const Color(0xFFE6EFFA)], //普通会员
    3: [const Color(0xFFC7C7C7), const Color(0xFFF2F2F2)], //未实名认证
  };

  final Map _unlockEquities = {
    0: 23, //SVIP
    1: 21, //VIP
    2: 5, //普通会员
    3: 2, //未实名认证
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 331.w,
      height: 662.w,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            _equitiesList[levelIndex],
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 71.w,
            child: RichText(
              text: TextSpan(
                text: "当前已解锁",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: _textColorMap[levelIndex],
                ),
                children: [
                  TextSpan(
                    text: " ${_unlockEquities[levelIndex]} ",
                    style: TextStyle(
                      color: kAppConfig.appThemeColor,
                    ),
                  ),
                  TextSpan(
                    text: "项服务",
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 113.w,
            left: 0,
            right: 0,
            child: Column(
              children:
                  List.generate(equitiesGroup.length, (section) => section)
                      .map((section) {
                List equities = equitiesGroup.values.toList()[section];

                return Column(
                  children: [
                    Text(
                      "${equitiesGroup.keys.toList()[section]}",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _textColorMap[levelIndex],
                      ),
                    ),
                    SizedBox(height: 15.w),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 15.w,
                      children: List.generate(equities.length, (index) => index)
                          .map((index) {
                        bool _lock = equities[index]["lock"] ?? false;
                        bool _free = equities[index]["free"] ?? false;
                        return InkWell(
                          onTap: () {
                            if (equitiesIdFeedback != null) {
                              equitiesIdFeedback!(equities[index]["id"]);
                            }
                          },
                          child: SizedBox(
                            width: 66.w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 44.w,
                                  height: 36.w,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 36.w,
                                        height: 36.w,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors:
                                                _gradientColorMap[levelIndex],
                                            begin: Alignment.bottomLeft,
                                            end: Alignment.topRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(36.w / 2),
                                          border: Border.all(
                                            width: 1.w,
                                            color: equities[index]["id"] ==
                                                    equitiesId
                                                ? _equitiesTextColorMap[
                                                        levelIndex]!
                                                    .withOpacity(_lock == false
                                                        ? 1
                                                        : 0.3)
                                                : const Color(0x51FFFFFF),
                                          ),
                                        ),
                                      ),
                                      Image.asset(
                                        "images/equities/" +
                                            equities[index]["icon"],
                                        width: 20.w,
                                        height: 21.w,
                                        color:
                                            _equitiesTextColorMap[levelIndex]!
                                                .withOpacity(
                                                    _lock == false ? 1 : 0.3),
                                      ),
                                      (equities[index]["count"].length > 0 &&
                                              _lock == false)
                                          ? Positioned(
                                              top: 0,
                                              right: 0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      kAppConfig.appThemeColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6.w),
                                                ),
                                                padding: EdgeInsets.only(
                                                  left: 3.w,
                                                  right: 3.w,
                                                  top: 1.w,
                                                  bottom: 1.w,
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  equities[index]["count"],
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 6.sp,
                                                    color:
                                                        const Color(0xFFFFFFFF),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : SizedBox(),
                                      _free
                                          ? Positioned(
                                              top: 0,
                                              right: 0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: _freeTextColorMap[
                                                      levelIndex],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6.w),
                                                ),
                                                padding: EdgeInsets.only(
                                                  left: 3.w,
                                                  right: 3.w,
                                                  top: 0,
                                                  bottom: 1.w,
                                                ),
                                                child: Text(
                                                  "免费",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 7.sp,
                                                    color:
                                                        const Color(0xFFFFFFFF),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : SizedBox(),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 3.w),
                                Text(
                                  equities[index]["name"],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: _equitiesTextColorMap[levelIndex]!
                                        .withOpacity(_lock == false ? 1 : 0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 25.w),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
