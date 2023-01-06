import 'dart:convert';

import 'package:common_utils/common_utils.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/config/environment_config.dart';
import 'package:oktoast/oktoast.dart';

EnvironmentConfig kAppConfig = EnvironmentConfig();

//验证身份证
bool isIdCard(String cardId) {
  if (cardId.length != 18) {
    return false; // 位数不够
  }
  // 身份证号码正则
  RegExp postalCode = new RegExp(
      r'^[1-9]\d{5}[1-9]\d{3}((0\d)|(1[0-2]))(([0|1|2]\d)|3[0-1])\d{3}([0-9]|[Xx])$');
  // 通过验证，说明格式正确，但仍需计算准确性
  if (!postalCode.hasMatch(cardId)) {
    return false;
  }
  //将前17位加权因子保存在数组里
  final List idCardList = [
    "7",
    "9",
    "10",
    "5",
    "8",
    "4",
    "2",
    "1",
    "6",
    "3",
    "7",
    "9",
    "10",
    "5",
    "8",
    "4",
    "2"
  ];
  //这是除以11后，可能产生的11位余数、验证码，也保存成数组
  final List idCardYArray = [
    '1',
    '0',
    '10',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
    '2'
  ];
  // 前17位各自乖以加权因子后的总和
  int idCardWiSum = 0;

  for (int i = 0; i < 17; i++) {
    int subStrIndex = int.parse(cardId.substring(i, i + 1));
    int idCardWiIndex = int.parse(idCardList[i]);
    idCardWiSum += subStrIndex * idCardWiIndex;
  }
  // 计算出校验码所在数组的位置
  int idCardMod = idCardWiSum % 11;
  // 得到最后一位号码
  String idCardLast = cardId.substring(17, 18);
  //如果等于2，则说明校验码是10，身份证号码最后一位应该是X
  if (idCardMod == 2) {
    if (idCardLast != 'x' && idCardLast != 'X') {
      return false;
    }
  } else {
    //用计算出的验证码与最后一位身份证号码匹配，如果一致，说明通过，否则是无效的身份证号码
    if (idCardLast != idCardYArray[idCardMod]) {
      return false;
    }
  }
  return true;
}

String timeLineFormat({
  required String date,
  String fullFormat = "yyyy年MM月dd日 HH:mm",
  String currentYearFormat = "MM月dd日 HH:mm",
  bool chatStyle = true,
}) {
  date =
      date.replaceAll("+08:00", "Z").replaceAll("T", " ").replaceAll("Z", "");

  DateTime _dateTime = DateUtil.getDateTime(
    DateUtil.formatDateStr(date),
  )!;
  int ms = _dateTime.millisecondsSinceEpoch;

  DateTime _locDate = DateTime.now();
  int _locTimeMs = _locDate.millisecondsSinceEpoch;

  if (chatStyle) {
    int elapsed = _locTimeMs - ms;
    if (elapsed < 0) {
      return DateUtil.formatDateMs(ms, format: "HH:mm");
    }

    if (DateUtil.isToday(ms, locMs: _locTimeMs)) {
      return DateUtil.formatDateMs(ms, format: "HH:mm");
    }

    if (DateUtil.isYesterdayByMs(ms, _locTimeMs)) {
      return "昨天 " + DateUtil.formatDateMs(ms, format: "HH:mm");
    }

    if (DateUtil.isWeek(ms, locMs: _locTimeMs)) {
      return DateUtil.getWeekdayByMs(ms, languageCode: "zh") +
          " " +
          DateUtil.formatDateMs(ms, format: "HH:mm");
    }
  }

  if (DateUtil.yearIsEqual(_dateTime, _locDate)) {
    return DateUtil.formatDateMs(ms, format: currentYearFormat);
  } else {
    return DateUtil.formatDateMs(ms, format: fullFormat);
  }
}

// 文件大小
String getFileSize(int limit, {int byte = 3}) {
  //内存转换
  try {
    String size = "";
    if (limit == 0) {
      size = "-";
    } else if (limit < 1 * 1024) {
      //小于1KB，则转化成B
      size = limit.toString();
      int length = size.indexOf(".") + byte;
      if (length > size.length) {
        length = size.length;
      }
      size = size.substring(0, length) + "B";
    } else if (limit < 1 * 1024 * 1024) {
      //小于1MB，则转化成KB
      size = (limit / 1024).toString();
      int length = size.indexOf(".") + byte;
      if (length > size.length) {
        length = size.length;
      }
      size = size.substring(0, length) + "KB";
    } else if (limit < 0.1 * 1024 * 1024 * 1024) {
      //小于0.1GB，则转化成MB
      size = (limit / (1024 * 1024)).toString();
      int length = size.indexOf(".") + byte;
      if (length > size.length) {
        length = size.length;
      }
      size = size.substring(0, length) + "MB";
    } else {
      //其他转化成GB
      size = (limit / (1024 * 1024 * 1024)).toString();
      int length = size.indexOf(".") + byte;
      if (length > size.length) {
        length = size.length;
      }
      size = size.substring(0, length) + "GB";
    }

    return size;
  } catch (e) {
    return "-";
  }
}

// 密码正则
bool passwordRegExp(String input) {
  RegExp mobile = new RegExp(
      r"^(?!_)(?=.*[a-zA-Z])(?=.*[~`!@#$%^&*,./])(?=.*[0-9])[a-zA-Z_0-9_~`!@#$%^&*,./][\S*]{7,16}$");
  bool isMatch = mobile.hasMatch(input);

  return isMatch;
}

// 手机号输入
String phoneFormat(String text) {
  //这里格式化整个输入文本
  text = text.replaceAll(RegExp(r"\s+\b|\b\s"), "");
  var string = "";
  for (int i = 0; i < text.length; i++) {
    // 这里第 4 位，与第 8 位，我们用空格填充
    if (i == 3 || i == 7) {
      if (text[i] != " ") {
        string = string + " ";
      }
    }
    string += text[i];
  }

  return string;
}

List<TextInputFormatter> phoneInputFormatters() {
  return [
    LengthLimitingTextInputFormatter(13),
    FilteringTextInputFormatter.allow(
      RegExp(r"[0-9]|\s+\b|\b\s"),
    ), //只能输入数字、空格
    TextInputFormatter.withFunction((oldValue, newValue) {
      String text = newValue.text;
      //获取光标左边的文本
      final positionStr = (text.substring(0, newValue.selection.baseOffset))
          .replaceAll(RegExp(r"\s+\b|\b\s"), "");
      //计算格式化后的光标位置
      int length = positionStr.length;
      var position = 0;
      if (length <= 3) {
        position = length;
      } else if (length <= 7) {
        // 因为前面的字符串里面加了一个空格
        position = length + 1;
      } else if (length <= 11) {
        // 因为前面的字符串里面加了两个空格
        position = length + 2;
      } else {
        // 号码本身为 11 位数字，因多了两个空格，故为 13
        position = 13;
      }

      //这里格式化整个输入文本
      text = text.replaceAll(RegExp(r"\s+\b|\b\s"), "");
      var string = "";
      for (int i = 0; i < text.length; i++) {
        // 这里第 4 位，与第 8 位，我们用空格填充
        if (i == 3 || i == 7) {
          if (text[i] != " ") {
            string = string + " ";
          }
        }
        string += text[i];
      }

      return TextEditingValue(
        text: string,
        selection: TextSelection.fromPosition(
            TextPosition(offset: position, affinity: TextAffinity.upstream)),
      );
    }),
  ];
}

/// 公共弹框
void utilsToast({
  required String msg,
  int milliseconds = 2000,
}) {
  dismissAllToast();

  Future.delayed(Duration(milliseconds: 10), () {
    showToast(
      "$msg",
      backgroundColor: const Color(0xFF000000),
      textStyle: TextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: 14.sp,
        height: 1.5,
      ),
      textPadding: EdgeInsets.all(10.w),
      radius: 4.w,
      duration: Duration(milliseconds: milliseconds),
      dismissOtherToast: true,
    );
  });
}

///带占位图网络图片
Widget networkImage(
  String? sources,
  Size? size,
  BorderRadius borderRadius, {
  String? placeholder,
  BoxFit fit: BoxFit.cover,
  bool memoryData = false,
  bool circularProgress = false,
}) {
  if (placeholder == null) {
    placeholder = "images/icon_placeholder@3x.png";
  }

  Widget? _stateWidget(ExtendedImageState state) {
    if (state.extendedImageLoadState == LoadState.loading &&
        circularProgress == true) {
      return Center(
        child: SizedBox(
          width: 20.w,
          height: 20.w,
          child: CircularProgressIndicator(strokeWidth: 1.5.w),
        ),
      );
    }

    if (state.extendedImageLoadState == LoadState.failed ||
        (state.extendedImageLoadState == LoadState.loading &&
            circularProgress == false)) {
      return placeholder != null
          ? Image.asset(
              placeholder,
              fit: fit,
              width: size == null ? null : size.width,
              height: size == null ? null : size.height,
            )
          : Container(
              width: size == null ? null : size.width,
              height: size == null ? null : size.height,
              color: const Color(0xFFEBECF0),
            );
    }

    return null;
  }

  return ClipRRect(
    child: (sources ?? "").length == 0
        ? Image.asset(
            placeholder,
            fit: fit,
            width: size == null ? null : size.width,
            height: size == null ? null : size.height,
          )
        : memoryData == true
            ? ExtendedImage.memory(
                base64Decode(sources!.replaceAll("data:image/png;base64,", "")),
                borderRadius: borderRadius,
                fit: fit,
                width: size == null ? null : size.width,
                height: size == null ? null : size.height,
                enableLoadState: circularProgress,
                loadStateChanged: _stateWidget,
              )
            : ExtendedImage.network(
                "$sources",
                cache: true,
                enableMemoryCache: true,
                clearMemoryCacheIfFailed: false,
                borderRadius: borderRadius,
                fit: fit,
                width: size == null ? null : size.width,
                height: size == null ? null : size.height,
                handleLoadingProgress: true,
                enableLoadState: circularProgress,
                loadStateChanged: _stateWidget,
              ),
    borderRadius: borderRadius,
  );
}
