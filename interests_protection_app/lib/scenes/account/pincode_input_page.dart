import 'dart:async';
import 'dart:math';

import 'package:common_utils/common_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/scenes/account/forgot_tab_page.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

bool _pincodeInputShow = false;

class PincodeInputPage extends StatefulWidget {
  final void Function(bool xpin)? verifyFeedback;
  const PincodeInputPage({
    Key? key,
    this.verifyFeedback,
  }) : super(key: key);

  @override
  State<PincodeInputPage> createState() => _PincodeInputPageState();

  static show(
    BuildContext context,
    void Function(bool xpin)? verifyFeedback,
  ) {
    if (_pincodeInputShow) {
      return;
    }

    _pincodeInputShow = true;
    showDialog(
      barrierColor: Colors.transparent,
      context: context,
      useSafeArea: false,
      builder: (context) {
        return PincodeInputPage(
          verifyFeedback: verifyFeedback,
        );
      },
    );
  }
}

class _PincodeInputPageState extends State<PincodeInputPage> {
  int _pinCodeCount = 4;
  List<int> _codeInputList = [];
  List<int> _randomCodeList = [];
  double _codeItemWidth = 0;
  double _codeItemHeight = 0;
  double _codeItemSpace = 1.w;
  Color _codeItemColor = const Color(0xFFF6F6F7);

  int _errorCount = 0;
  bool _verifyPincodeProgress = false;
  String _remaining = "";
  Timer? _remainingTimer;

  // ιθ―ηΆζ
  void _getRemaining(
    int count,
    String errorDate,
    void Function(String remaining) feedback,
  ) {
    int _totalMinutes = 5 * (count - 5);
    if (_totalMinutes == 0) {
      _totalMinutes = 1;
    }

    String _tempRemaining = "";
    DateTime? _errorDateTime = DateUtil.getDateTime(errorDate);
    if (_errorDateTime != null) {
      Duration _diffDuration = _errorDateTime.difference(DateTime.now());
      _totalMinutes = _diffDuration.inMinutes;
      int _seconds = _diffDuration.inSeconds;
      if (_seconds < 1) {
        _tempRemaining = "";
      } else {
        if (_seconds < 60) {
          _tempRemaining = "θ―·$_secondsη§ειθ―";
        } else {
          _totalMinutes += 1;
          _tempRemaining = "θ―·$_totalMinutesειειθ―";
        }
      }
    } else {
      _tempRemaining = "θ―·$_totalMinutesειειθ―";
    }

    feedback(_tempRemaining);

    if (_tempRemaining.length == 0) {
      if (_remainingTimer != null) {
        _remainingTimer?.cancel();
        _remainingTimer = null;
      }
    }
  }

  void _remainingLoop() {
    if (_remainingTimer != null) {
      _remainingTimer?.cancel();
      _remainingTimer = null;
    }

    _remainingTimer = Timer.periodic(Duration(seconds: 1), (_) {
      StorageUtils.getPincodeError((count, errorDate) {
        if (count >= 5) {
          _getRemaining(count, errorDate, (remaining) {
            if (remaining != _remaining) {
              _remaining = remaining;
              setState(() {});
            }
          });
        }
      });
    });
  }

  void _retryState() {
    StorageUtils.getPincodeError((count, errorDate) {
      _errorCount = count;
      debugPrint("εε²ιθ――ζ¬‘ζ°:$_errorCount");
      if (count >= 5) {
        _getRemaining(count, errorDate, (remaining) {
          if (remaining != _remaining) {
            _remaining = remaining;
            setState(() {
              _remainingLoop();
            });
          }
        });
      } else {
        if (_remainingTimer != null) {
          _remainingTimer?.cancel();
          _remainingTimer = null;
          _remaining = "";
          setState(() {});
        }
      }
    });
  }

  // ζ ‘ιͺη»ζ
  void _verifyPincode() async {
    if (_codeInputList.length == 0) {
      return;
    }

    _verifyPincodeProgress = true;
    setState(() {});

    String _pincode = _codeInputList.join("");
    String _encryptPincode = await CryptoUtils.encryptPinCode(_pincode);

    SVProgressHUD.show();
    if (widget.verifyFeedback != null) {
      // ιͺθ―ιθΏ
      void _pinCodePass({bool xpin = false}) {
        StorageUtils.setPincodeError(0, () {});
        Get.find<AppHomeController>().appState = AppCurrentState.normal;
        Get.find<AppHomeController>().xpinMode = xpin;

        if (widget.verifyFeedback != null) {
          widget.verifyFeedback!(xpin);
        }

        Future.delayed(Duration(milliseconds: 200), () {
          SVProgressHUD.dismiss();
          Get.back();
        });
      }

      void _errorPinCheck() {
        utilsToast(msg: "PINη ιθ――");
        _codeInputList.clear();
        _verifyPincodeProgress = false;
        _errorCount += 1;
        setState(() {});

        StorageUtils.setPincodeError(_errorCount, () {
          _retryState();

          Future.delayed(Duration(milliseconds: 200), () {
            SVProgressHUD.dismiss();
          });
        });
      }

      // ζ ‘ιͺPINη 
      void _checkNetPin({String localXpin = ""}) {
        AccountApi.checkPincode(params: {
          "pin": localXpin.length > 0 ? localXpin : _encryptPincode,
        }).then((value) async {
          bool xpin = !value["pin"]; // ζ―ε¦ pin true: pin η ; false: η΄§ζ₯ pin η 
          if (xpin) {
            debugPrint("η΄§ζ₯PINη ζΈη©Ίθε€©θ?°ε½");
            // ζΈη©Ίθε€©θ?°ε½
            await StorageUtils.emptyCurrnetChatRecord();
            _pinCodePass(xpin: true);
          } else {
            StorageUtils.setPincode(_encryptPincode);
            _pinCodePass();
          }
        }).catchError((error) async {
          // ζ¬ε°ε€ζ­ζ―ε¦η΄§ζ₯PINη 
          if (localXpin.length > 0) {
            debugPrint("η΄§ζ₯PINη ζΈη©Ίθε€©θ?°ε½");
            // ζΈη©Ίθε€©θ?°ε½
            await StorageUtils.emptyCurrnetChatRecord();
            _pinCodePass(xpin: true);
          } else {
            _errorPinCheck();
          }
        });
      }

      // ζ¬ε°ζ ‘ιͺ
      var result = await Connectivity().checkConnectivity();
      if (result != ConnectivityResult.none) {
        StorageUtils.getPincode((pincode) {
          Future.delayed(Duration(milliseconds: 300), () async {
            if (pincode.length == 0) {
              _checkNetPin();
            } else {
              // ζ¬ε°ζ ‘ιͺζ?ιPINη 
              if (_encryptPincode == pincode) {
                _checkNetPin();
              } else {
                // θ§£ε―η΄§ζ₯PINη 
                String _xpin = await CryptoUtils.decryptXPIN(
                  Get.find<AppHomeController>().accountModel.xpin,
                  Get.find<AppHomeController>().accountModel.userId,
                );

                // ζ¬ε°ε€ζ­ζ―ε¦η΄§ζ₯PINη 
                if (_pincode == _xpin) {
                  _checkNetPin(
                    localXpin: Get.find<AppHomeController>().accountModel.xpin,
                  );
                } else {
                  _errorPinCheck();
                }
              }
            }
          });
        });
      } else {
        utilsToast(msg: "η½η»δΈδ½³");
        _verifyPincodeProgress = false;
        setState(() {});

        Future.delayed(Duration(milliseconds: 200), () {
          SVProgressHUD.dismiss();
        });
      }
    } else {
      Future.delayed(Duration(milliseconds: 300), () {
        SVProgressHUD.dismiss();

        Get.back(result: "$_pincode");
      });
    }
  }

  // ζ°ε­ι?η
  Widget _baseItemWidget(int index) {
    return Container(
      height: _codeItemHeight,
      color: _codeItemColor,
      child: MaterialButton(
        onPressed: _remaining.length > 0
            ? null
            : (index < _randomCodeList.length - 1 ||
                    index == _randomCodeList.length)
                ? () {
                    if (_codeInputList.length != _pinCodeCount) {
                      if (index == _randomCodeList.length) {
                        _codeInputList.add(_randomCodeList.last);
                      } else {
                        _codeInputList.add(_randomCodeList[index]);
                      }

                      if (_codeInputList.length == _pinCodeCount) {
                        _verifyPincode();
                      }
                    }

                    setState(() {});
                  }
                : null,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: index < _randomCodeList.length - 1
            ? Text(
                "${_randomCodeList[index]}",
                style: TextStyle(
                  color: const Color(0xFF2A2B2C),
                  fontSize: 25.sp,
                ),
              )
            : index == _randomCodeList.length - 1
                ? Container()
                : index == _randomCodeList.length
                    ? Text(
                        "${_randomCodeList.last}",
                        style: TextStyle(
                          color: const Color(0xFF2A2B2C),
                          fontSize: 25.sp,
                        ),
                      )
                    : Container(),
      ),
    );
  }

  // ζδΉ±ζ°η»
  List<int> _shuffleList() {
    int _getRandomInt(int min, int max) {
      final _random = new Random();
      return _random.nextInt((max - min).floor()) + min;
    }

    List<int> newArr = [];
    newArr.addAll(_randomCodeList);
    for (var i = 1; i < newArr.length; i++) {
      var j = _getRandomInt(0, i);
      var t = newArr[i];
      newArr[i] = newArr[j];
      newArr[j] = t;
    }

    return newArr;
  }

  Widget _virtualKeyboard() {
    return _randomCodeList.length > 0
        ? GestureDetector(
            onTap: () {},
            child: Container(
              color: const Color(0xFFEBECED),
              padding: EdgeInsets.fromLTRB(
                0,
                _codeItemSpace,
                0,
                _codeItemSpace,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: _codeItemSpace,
                            crossAxisSpacing: _codeItemSpace,
                            childAspectRatio: _codeItemWidth / _codeItemHeight,
                          ),
                          itemBuilder: (context, index) {
                            return _baseItemWidget(index);
                          },
                          itemCount: _randomCodeList.length + 2,
                        ),
                      ),
                      IgnorePointer(
                        ignoring:
                            _verifyPincodeProgress || _remaining.length > 0,
                        child: Column(
                          children: [
                            // ε ι€
                            SizedBox(
                              width: 96.w,
                              height: 100.w,
                              child: MaterialButton(
                                color: _codeItemColor,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero),
                                onPressed: () {
                                  if (_codeInputList.length > 0) {
                                    _codeInputList.removeLast();
                                    setState(() {});
                                  }
                                },
                                child: Image.asset(
                                  "images/pincode_cannel@2x.png",
                                  width: 26.w,
                                  height: 19.w,
                                ),
                              ),
                            ),
                            SizedBox(height: _codeItemSpace),
                            // η‘?ε?
                            SizedBox(
                              width: 96.w,
                              height: 100.w,
                              child: MaterialButton(
                                color: kAppConfig.appThemeColor,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero),
                                onPressed: () {
                                  _verifyPincode();
                                },
                                child: Text(
                                  "η‘?ε?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFFFFFFFF),
                                    fontSize: 21.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: MediaQuery.of(context).padding.bottom,
                    color: _codeItemColor,
                  ),
                ],
              ),
            ),
          )
        : SizedBox();
  }

  @override
  void initState() {
    for (var i = 0; i < 10; i++) {
      _randomCodeList.add(i);
    }

    super.initState();

    _randomCodeList = _shuffleList();

    if (Get.arguments != null) {
      _pinCodeCount = Get.arguments["pinCodeCount"] ?? 4;
    }

    _retryState();
  }

  @override
  void dispose() {
    _pincodeInputShow = false;
    if (_remainingTimer != null) {
      _remainingTimer?.cancel();
      _remainingTimer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_codeItemWidth == 0) {
      _codeItemWidth =
          (MediaQuery.of(context).size.width - _codeItemSpace * 3) / 3;
    }

    if (_codeItemHeight == 0) {
      _codeItemHeight = (203.w - _codeItemSpace * 5) / 3;
    }

    return widget.verifyFeedback != null
        ? GestureDetector(
            onTap: () {
              Get.back();
            },
            child: Material(
              color: const Color(0x7F000000),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 33.w,
                    right: 33.w,
                    top: 155.w + MediaQuery.of(context).padding.top,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin: EdgeInsets.only(bottom: 155.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(20.w),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            SizedBox(height: 10.w),
                            Text(
                              "θ―·θΎε₯PINη ",
                              style: TextStyle(
                                color: const Color(0xFF000000),
                                fontSize: 18.sp,
                              ),
                            ),
                            SizedBox(height: 15.w),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  List.generate(_pinCodeCount, (index) => index)
                                      .map((index) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                      left: index == 0 ? 0 : 20.w),
                                  child: Container(
                                    width: 47.w,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF),
                                      border: Border.all(
                                        width: 0.5.w,
                                        color: kAppConfig.appPlaceholderColor,
                                      ),
                                    ),
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                      "${index < _codeInputList.length ? _codeInputList[index] : ''}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFF000000),
                                        fontSize: 50.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 15.w / 2),
                            _remaining.length > 0
                                ? Container(
                                    margin: EdgeInsets.only(top: 15.w / 2),
                                    child: Text(
                                      _remaining,
                                      style: TextStyle(
                                        color: kAppConfig.appErrorColor,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  )
                                : SizedBox(),
                            MaterialButton(
                              padding: EdgeInsets.only(
                                  top: 15.w / 2, bottom: 15.w / 2),
                              onPressed: () {
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) {
                                    return ForgotTabPage(tab: 1);
                                  },
                                  fullscreenDialog: true,
                                ))
                                    .then((value) {
                                  _retryState();
                                });
                              },
                              child: Text(
                                "ιη½?PINη ",
                                style: TextStyle(
                                  color: const Color(0xFF3A587A),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 15.w / 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child:
                        // θζι?η
                        _virtualKeyboard(),
                  ),
                ],
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              leading: AppbarBack(),
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 29.w),
                    Text(
                      "θΎε₯PINη ",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: 24.sp,
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.only(top: 59.w, left: 49.w, right: 49.w),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            alignment: Alignment.topCenter,
                            height: 73.w,
                            child: Row(
                              children:
                                  List.generate(_pinCodeCount, (index) => index)
                                      .map((index) {
                                return Expanded(
                                  child: Container(
                                    height: 50.w,
                                    width: 53.w,
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                      "${index < _codeInputList.length ? _codeInputList[index] : ''}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFF000000),
                                        fontSize: 50.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Positioned(
                            bottom: 10.w,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children:
                                  List.generate(_pinCodeCount, (index) => index)
                                      .map((index) {
                                return Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 53.w,
                                      height: 2.w,
                                      color: index < _codeInputList.length
                                          ? Colors.transparent
                                          : index == _codeInputList.length
                                              ? const Color(0xFF000000)
                                              : kAppConfig.appPlaceholderColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // θζι?η
                _virtualKeyboard(),
              ],
            ),
            resizeToAvoidBottomInset: false,
          );
  }
}
