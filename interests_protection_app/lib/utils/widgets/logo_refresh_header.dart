import 'dart:math';

import 'package:flutter/material.dart'
    hide RefreshIndicator, RefreshIndicatorState;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class LogoRefreshHeader extends RefreshIndicator {
  final bool initialRefresh;
  const LogoRefreshHeader({
    Key? key,
    double height: 60.0,
    Duration completeDuration: const Duration(milliseconds: 1000),
    RefreshStyle refreshStyle: RefreshStyle.Follow,
    this.initialRefresh = true,
  }) : super(
          key: key,
          completeDuration: completeDuration,
          refreshStyle: refreshStyle,
          height: height,
        );

  @override
  State<StatefulWidget> createState() {
    return _LogoRefreshHeaderState();
  }
}

class _LogoRefreshHeaderState extends RefreshIndicatorState<LogoRefreshHeader>
    with TickerProviderStateMixin {
  double _offsetProgress = 0;
  AnimationController? _animationController;
  Animation<double>? _angleAnimation;

  void _animationDispose() {
    _offsetProgress = 0;

    if (_animationController != null) {
      _animationController?.reset();
      _animationController?.dispose();
      _animationController = null;
      _angleAnimation?.removeListener(() {});
      _angleAnimation = null;
    }
  }

  void _animationStart() {
    _animationDispose();

    _animationController = AnimationController(
      vsync: this,
      duration: widget.completeDuration,
    );

    _angleAnimation = Tween(begin: 0.0, end: 1.0).animate(
      _animationController!,
    )..addListener(() {});
    _animationController?.forward();
  }

  @override
  void onOffsetChange(double offset) {
    _offsetProgress = (offset / widget.height);
    if (_offsetProgress > 1) {
      _offsetProgress = 1;
    } else if (_offsetProgress < -1) {
      _offsetProgress = -1;
    }

    update();
    super.onOffsetChange(offset);
  }

  @override
  void onModeChange(RefreshStatus? mode) {
    if (mode == RefreshStatus.idle) {
      _animationDispose();
      update();
    }

    super.onModeChange(mode);
  }

  @override
  Future<void> readyToRefresh() {
    _offsetProgress = 0;
    _animationStart();
    update();

    return super.readyToRefresh();
  }

  @override
  Future<void> endRefresh() {
    return super.endRefresh();
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialRefresh == true) {
      _animationStart();
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget buildContent(BuildContext context, RefreshStatus? mode) {
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: _offsetProgress * ((widget.height - 28.w) / 2) + 10.w,
            child: _animationController != null
                ? AnimatedBuilder(
                    animation: _animationController!,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: pi * _angleAnimation!.value * 2,
                        child: Image.asset(
                          "images/logoqiu_up.png",
                          width: 28.w,
                          height: 28.w,
                        ),
                      );
                    },
                  )
                : Transform.scale(
                    scale: (0.6 + _offsetProgress).abs() > 1
                        ? 1
                        : (0.6 + _offsetProgress).abs() < 0.6
                            ? 0.6
                            : (0.6 + _offsetProgress).abs(),
                    child: Transform.rotate(
                      angle: pi * _offsetProgress,
                      child: Image.asset(
                        "images/logoqiu.png",
                        width: 28.w,
                        height: 28.w,
                      ),
                    ),
                  ),
          )
        ],
      ),
    );
  }
}
