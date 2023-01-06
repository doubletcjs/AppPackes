import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LaunchGuidance extends StatefulWidget {
  final void Function() closeAction;
  const LaunchGuidance({
    super.key,
    required this.closeAction,
  });

  @override
  State<LaunchGuidance> createState() => _LaunchGuidanceState();

  static show(BuildContext context, void Function() closeAction) {
    showGeneralDialog(
      context: context,
      barrierColor: const Color(0x7F000000),
      pageBuilder: (context, animation, secondaryAnimation) {
        return WillPopScope(
            child: LaunchGuidance(closeAction: closeAction),
            onWillPop: () {
              return Future(() => false);
            });
      },
    );
  }
}

class _LaunchGuidanceState extends State<LaunchGuidance> {
  int _guidanceIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0x14000000),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _guidanceIndex == 0
                ? Positioned(
                    top: 44.w + MediaQuery.of(context).padding.top,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        _guidanceIndex = 1;
                        setState(() {});
                      },
                      child: Image.asset(
                        "images/launch_guide_1@2x.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : _guidanceIndex == 1
                    ? Positioned(
                        left: 0,
                        right: 0,
                        bottom: MediaQuery.of(context).padding.bottom,
                        child: GestureDetector(
                          onTap: () {
                            _guidanceIndex = 2;
                            setState(() {});
                          },
                          child: Image.asset(
                            "images/launch_guide_2@2x.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : _guidanceIndex == 2
                        ? Positioned(
                            left: 0,
                            right: 0,
                            bottom: MediaQuery.of(context).padding.bottom,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.closeAction();
                              },
                              child: Image.asset(
                                "images/launch_guide_3@2x.png",
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : SizedBox(),
          ],
        ),
      ),
    );
  }
}
