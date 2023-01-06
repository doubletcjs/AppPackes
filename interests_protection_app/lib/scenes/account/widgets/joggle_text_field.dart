import 'dart:math';

import 'package:country_list_pick/country_list_pick.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/scenes/account/pincode_input_page.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

enum JoggleTextFieldType { mobile, password, pincode }

class JoggleTextField extends StatefulWidget {
  final JoggleTextFieldController? controller;
  final JoggleTextFieldType textFieldType;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final void Function(String areaCode)? areaCodeHandle;
  final String? placeholder;
  final TextInputAction? textInputAction;
  final int? maxLength;
  const JoggleTextField({
    Key? key,
    required this.controller,
    required this.textFieldType,
    this.onEditingComplete,
    this.onChanged,
    this.placeholder,
    this.areaCodeHandle,
    this.textInputAction,
    this.onSubmitted,
    this.maxLength,
  }) : super(key: key);

  @override
  State<JoggleTextField> createState() => _JoggleTextFieldState();
}

class _JoggleTextFieldState extends State<JoggleTextField>
    with TickerProviderStateMixin {
  late JoggleTextFieldController _controller;
  late TextEditingController _editingController;
  late FocusNode _focusNode;
  String _areaCode = "+86";
  bool _obscureText = true;
  String _placeholder = "";

  final _shakeCount = 5;
  final _shakeDuration = Duration(milliseconds: 600);
  late final AnimationController _shakeController =
      AnimationController(vsync: this, duration: _shakeDuration);

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? JoggleTextFieldController();
    _editingController = _controller.editingController;
    _focusNode = _controller.focusNode;

    _placeholder = ((widget.placeholder ?? "").length > 0)
        ? widget.placeholder!
        : (widget.textFieldType == JoggleTextFieldType.password
            ? "请输入密码"
            : widget.textFieldType == JoggleTextFieldType.pincode
                ? "请输入PIN码"
                : "请输入手机号");

    _focusNode.addListener(() {
      setState(() {});
    });

    _shakeController.addListener(() {
      if (_shakeController.status == AnimationStatus.completed) {
        _shakeController.reset();
      }

      setState(() {});
    });

    _controller.shakeController = _shakeController;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final sineValue = sin(_shakeCount * 2 * pi * _shakeController.value);
        return Transform.translate(
          offset: Offset(sineValue * 10, 0),
          child: child,
        );
      },
      child: Container(
        height: 48.w,
        padding: EdgeInsets.only(left: 19.w, right: 17.w),
        decoration: BoxDecoration(
          color: _shakeController.status == AnimationStatus.forward
              ? kAppConfig.appDisableColor
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(48.w / 2),
        ),
        child: Row(
          children: [
            Image.asset(
              "images/${widget.textFieldType == JoggleTextFieldType.password ? 'login_password@3x.png' : widget.textFieldType == JoggleTextFieldType.pincode ? 'login_pin@3x.png' : 'login_phone@3x.png'}",
              width: 21.w,
              height: 21.w,
              color: _shakeController.status == AnimationStatus.forward
                  ? Colors.white
                  : null,
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: InkWell(
                onTap: widget.textFieldType == JoggleTextFieldType.pincode
                    ? () {
                        FocusScope.of(context).requestFocus(FocusNode());

                        Get.to(PincodeInputPage())?.then((value) {
                          if (value is String && value.length > 0) {
                            _editingController.text = "$value";
                            setState(() {});

                            if (widget.onChanged != null) {
                              widget.onChanged!("$value");
                            }
                          }
                        });
                      }
                    : null,
                child: TextField(
                  controller: _editingController,
                  focusNode: _focusNode,
                  enabled: widget.textFieldType == JoggleTextFieldType.pincode
                      ? false
                      : true,
                  style: TextStyle(
                    color: _controller.errorTextFormat
                        ? kAppConfig.appErrorColor
                        : (_shakeController.status == AnimationStatus.forward
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF666666)),
                    fontSize: 20.sp,
                  ),
                  maxLength: widget.maxLength,
                  obscureText:
                      widget.textFieldType == JoggleTextFieldType.mobile
                          ? false
                          : _obscureText,
                  keyboardType:
                      widget.textFieldType == JoggleTextFieldType.password
                          ? TextInputType.text
                          : TextInputType.numberWithOptions(decimal: true),
                  textInputAction:
                      widget.textInputAction ?? TextInputAction.done,
                  inputFormatters:
                      (widget.textFieldType == JoggleTextFieldType.pincode)
                          ? [
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[0-9]"),
                              ), //只能输入数字
                              FilteringTextInputFormatter.deny(
                                  RegExp('[\\s]')) // 空格
                            ]
                          : (widget.textFieldType == JoggleTextFieldType.mobile)
                              ? phoneInputFormatters()
                              : [
                                  FilteringTextInputFormatter.deny(
                                      RegExp('[\\s]')), // 空格
                                ],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _placeholder,
                    hintStyle: TextStyle(
                      color: _shakeController.status == AnimationStatus.forward
                          ? const Color(0xFFFFFFFF)
                          : kAppConfig.appPlaceholderColor,
                      fontSize: 15.sp,
                    ),
                    counterText: "",
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (widget.onChanged != null) {
                      widget.onChanged!(value);
                    }
                  },
                  onEditingComplete: widget.onEditingComplete,
                  onSubmitted: (value) {
                    if (value.trim().length > 0) {
                      if (widget.onSubmitted != null) {
                        widget.onSubmitted!(value);
                      }
                    } else {
                      _focusNode.requestFocus();
                    }
                  },
                ),
              ),
            ),
            SizedBox(width: 11.w),
            widget.textFieldType == JoggleTextFieldType.mobile
                ? (_editingController.text.trim().length > 0
                    ? InkWell(
                        onTap: () {
                          _editingController.clear();
                          _controller.errorTextFormat = false;
                          setState(() {});

                          if (widget.onChanged != null) {
                            widget.onChanged!("");
                          }
                        },
                        child: Image.asset(
                          "images/login_clean@2x.png",
                          width: 16.w,
                          height: 16.w,
                          color:
                              _shakeController.status == AnimationStatus.forward
                                  ? const Color(0xFFFFFFFF)
                                  : null,
                        ),
                      )
                    : CountryListPick(
                        appBar: AppBar(
                          title: const Text("国家选择"),
                          leading: AppbarBack(),
                        ),
                        useUiOverlay: false,
                        theme: CountryTheme(
                          isShowFlag: false,
                          isShowTitle: false,
                          isShowCode: true,
                          isDownIcon: false,
                          showEnglishName: false,
                          codeStyle: TextStyle(
                            color: const Color(0xFF666666),
                            fontSize: 15.sp,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        initialSelection: _areaCode,
                        onChanged: (value) {
                          _areaCode = value!.dialCode!;
                          if (widget.areaCodeHandle != null) {
                            widget.areaCodeHandle!(_areaCode);
                          }
                        },
                      ))
                : InkWell(
                    onTap: () {
                      _obscureText = !_obscureText;
                      setState(() {});
                    },
                    child: Image.asset(
                      !_obscureText
                          ? "images/login_show@3x.png"
                          : "images/login_hide@3x.png",
                      width: 16.w,
                      height: 16.w,
                      color: _shakeController.status == AnimationStatus.forward
                          ? const Color(0xFFFFFFFF)
                          : null,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class JoggleTextFieldController extends ChangeNotifier {
  TextEditingController editingController = TextEditingController();
  FocusNode focusNode = FocusNode();
  bool errorTextFormat = false;

  AnimationController? shakeController;

  @override
  void dispose() {
    editingController.dispose();
    focusNode.removeListener(() {});
    focusNode.dispose();

    super.dispose();
  }
}
