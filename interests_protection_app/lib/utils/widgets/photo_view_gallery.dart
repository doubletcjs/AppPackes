import 'dart:convert';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhotoViewGalleryPage extends StatefulWidget {
  final List images;
  final int initIndex;
  final void Function(int index)? deleteAction;

  PhotoViewGalleryPage({
    Key? key,
    required this.images,
    required this.initIndex,
    this.deleteAction,
  }) : super(key: key);

  @override
  _PhotoViewGalleryPageState createState() => _PhotoViewGalleryPageState();

  static void show(BuildContext context, PhotoViewGalleryPage galleryPage) {
    Navigator.of(context).push(
      FadeRoute(
        page: galleryPage,
      ),
    );
  }
}

class _PhotoViewGalleryPageState extends State<PhotoViewGalleryPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  List _imageDataList = [];

  Widget? _stateWidget(ExtendedImageState state) {
    if (state.extendedImageLoadState == LoadState.loading) {
      return Center(
        child: SizedBox(
          width: 25.w,
          height: 25.w,
          child: CircularProgressIndicator(strokeWidth: 1.5.w),
        ),
      );
    }

    if (state.extendedImageLoadState == LoadState.failed) {
      return Center(
        child: Icon(
          Icons.error,
          size: 25.w,
          color: Colors.red,
        ),
      );
    }

    return null;
  }

  // 双击
  final List<GlobalKey<ExtendedImageGestureState>> _gestureKeyList = [];
  final GestureConfig _gestureConfig = GestureConfig(
    inPageView: true,
    initialScale: 1.0,
    minScale: 0.8,
    maxScale: 3.0,
  );

  Animation<double>? _animation;
  var _animationListener;
  late AnimationController _animationController;
  late ExtendedPageController _pageController;

  void _onDoubleTap(ExtendedImageGestureState state, int index) {
    //remove old
    _animation?.removeListener(_animationListener);
    //stop pre
    _animationController.stop();
    //reset to use
    _animationController.reset();

    var _currentState = _gestureKeyList[index].currentState!;
    var _position = state.pointerDownPosition;
    double begin = _currentState.gestureDetails!.totalScale!;
    double end = 1;

    if (_currentState.gestureDetails!.totalScale! < _gestureConfig.maxScale) {
      begin = _currentState.gestureDetails!.totalScale!;
      end = _gestureConfig.maxScale;
    } else {
      end = _gestureConfig.initialScale;
    }

    _animationListener = () {
      state.handleDoubleTap(
        scale: _animation?.value,
        doubleTapPosition: _position,
      );
    };

    _animation = _animationController.drive(
      Tween<double>(begin: begin, end: end),
    );

    _animation?.addListener(_animationListener);
    _animationController.forward();
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _imageDataList = List.from(widget.images);
    _currentIndex = this.widget.initIndex;

    _pageController = ExtendedPageController(
      initialPage: _currentIndex,
      pageSpacing: _imageDataList.length == 1 ? 0 : 15.w,
    );

    _imageDataList.forEach((element) {
      _gestureKeyList.add(GlobalKey<ExtendedImageGestureState>());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animation?.removeListener(_animationListener);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Get.back();
              },
              onVerticalDragEnd: (details) {
                var _currentState =
                    _gestureKeyList[_currentIndex].currentState!;
                if (_currentState.gestureDetails!.totalScale! ==
                    _gestureConfig.initialScale) {
                  Get.back();
                }
              },
              child: Container(
                color: Colors.transparent,
                child: ExtendedImageGesturePageView.builder(
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    var item = _imageDataList[index];
                    bool _isMemory = false;
                    bool _isFile = false;
                    if (item is String && item.startsWith("http") == false) {
                      _isMemory = true;
                    } else if (item is File) {
                      _isFile = true;
                    }

                    Widget image = _isMemory
                        ? ExtendedImage.memory(
                            base64Decode(
                                item.replaceAll("data:image/png;base64,", "")),
                            fit: BoxFit.contain,
                            mode: ExtendedImageMode.gesture,
                            extendedImageGestureKey: _gestureKeyList[index],
                            gaplessPlayback: true,
                            clearMemoryCacheIfFailed: false,
                            onDoubleTap: (state) {
                              _onDoubleTap(state, index);
                            },
                            initGestureConfigHandler: (state) {
                              return _gestureConfig;
                            },
                            loadStateChanged: _stateWidget,
                            enableLoadState: true,
                          )
                        : _isFile
                            ? ExtendedImage.file(
                                item,
                                fit: BoxFit.contain,
                                mode: ExtendedImageMode.gesture,
                                extendedImageGestureKey: _gestureKeyList[index],
                                gaplessPlayback: true,
                                clearMemoryCacheIfFailed: false,
                                onDoubleTap: (state) {
                                  _onDoubleTap(state, index);
                                },
                                initGestureConfigHandler: (state) {
                                  return _gestureConfig;
                                },
                                loadStateChanged: _stateWidget,
                                enableLoadState: true,
                              )
                            : ExtendedImage.network(
                                item,
                                fit: BoxFit.contain,
                                cache: true,
                                enableMemoryCache: true,
                                clearMemoryCacheIfFailed: false,
                                mode: ExtendedImageMode.gesture,
                                extendedImageGestureKey: _gestureKeyList[index],
                                gaplessPlayback: true,
                                onDoubleTap: (state) {
                                  _onDoubleTap(state, index);
                                },
                                enableLoadState: true,
                                initGestureConfigHandler: (state) {
                                  return _gestureConfig;
                                },
                                loadStateChanged: _stateWidget,
                                handleLoadingProgress: true,
                              );
                    image = image;
                    if (index == _currentIndex) {
                      return Hero(
                        tag: "image_" + index.toString(),
                        child: image,
                      );
                    } else {
                      return image;
                    }
                  },
                  itemCount: _imageDataList.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                ),
              ),
            ),
          ),
          Positioned(
            //图片index显示
            top: MediaQuery.of(context).padding.top + 15.w,
            width: MediaQuery.of(context).size.width,
            child: _imageDataList.length == 0
                ? SizedBox()
                : Center(
                    child: Text(
                      "${_currentIndex + 1}/${_imageDataList.length}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
          ),
          Positioned(
            //右上角关闭按钮
            right: 5.w,
            left: widget.deleteAction == null ? null : 0,
            top: MediaQuery.of(context).padding.top,
            child: widget.deleteAction == null
                ? MaterialButton(
                    child: Icon(
                      Icons.close,
                      size: 30.w,
                      color: Colors.white,
                    ),
                    minWidth: 44.w,
                    height: 44.w,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22.w),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppbarBack(iconColor: const Color(0xFFFFFFFF)),
                      _imageDataList.length == 0
                          ? SizedBox()
                          : Row(
                              children: [
                                MaterialButton(
                                  child: Text(
                                    "删除",
                                    style: TextStyle(
                                      color: const Color(0xFFFFFFFF),
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                  minWidth: 44.w,
                                  height: 44.w,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22.w),
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    if (widget.deleteAction != null) {
                                      widget.deleteAction!(_currentIndex);
                                    }

                                    _imageDataList.removeAt(_currentIndex);

                                    if (_imageDataList.length == 0) {
                                      _currentIndex = 0;
                                      setState(() {});
                                      Navigator.of(context).pop();
                                    } else {
                                      setState(() {
                                        if (_currentIndex >
                                            _imageDataList.length - 1) {
                                          _currentIndex = 0;
                                        }

                                        _pageController
                                            .jumpToPage(_currentIndex);
                                      });
                                    }
                                  },
                                ),
                                SizedBox(width: 7.w),
                              ],
                            )
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

//渐隐动画
class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
}
