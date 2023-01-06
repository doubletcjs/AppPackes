import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/logo_refresh_header.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

enum RefreshUtilStatus {
  normal,
  emptyData,
  networkFailure,
  locationFailure,
}

class RefreshUtilWidget extends StatefulWidget {
  final Widget child;
  final RefreshUtilController refreshController;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final VoidCallback? statusFeedback;
  final List<Widget>? slivers;
  final ScrollPhysics? scrollPhysics;
  const RefreshUtilWidget({
    Key? key,
    required this.refreshController,
    required this.child,
    this.onRefresh,
    this.onLoadMore,
    this.statusFeedback,
    this.slivers,
    this.scrollPhysics,
  }) : super(key: key);

  @override
  State<RefreshUtilWidget> createState() => _RefreshUtilWidgetState();

  // 无网络
  static Widget networkFailurePlaceholder(final VoidCallback? statusFeedback) {
    return Container(
      padding: EdgeInsets.only(top: 35.w),
      color: const Color(0xFFFFFFFF),
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            "images/network_placeholder@2x.png",
            fit: BoxFit.cover,
          ),
          SizedBox(height: 14.w),
          MaterialButton(
            onPressed: () {
              if (statusFeedback != null) {
                statusFeedback();
              }
            },
            minWidth: 120.w,
            height: 44.w,
            color: kAppConfig.appThemeColor,
            elevation: 0,
            highlightElevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(44.w / 2),
            ),
            child: Text(
              "刷新",
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize: 15.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 无定位
  static Widget locationFailurePlaceholder(final VoidCallback? statusFeedback) {
    return Container(
      padding: EdgeInsets.only(top: 35.w),
      color: const Color(0xFFFFFFFF),
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            "images/location_placeholder@2x.png",
            fit: BoxFit.cover,
          ),
          SizedBox(height: 14.w),
          MaterialButton(
            onPressed: () {
              if (statusFeedback != null) {
                statusFeedback();
              }
            },
            minWidth: 120.w,
            height: 44.w,
            color: kAppConfig.appThemeColor,
            elevation: 0,
            highlightElevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(44.w / 2),
            ),
            child: Text(
              "开启定位",
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize: 15.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 空数据
  static Widget emptyDataPlaceholder() {
    return Container(
      padding: EdgeInsets.only(top: 35.w),
      color: const Color(0xFFFFFFFF),
      alignment: Alignment.topCenter,
      child: Image.asset(
        "images/emptydata_placeholder@2x.png",
        fit: BoxFit.cover,
      ),
    );
  }
}

class _RefreshUtilWidgetState extends State<RefreshUtilWidget>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController =
      ScrollController(initialScrollOffset: 0);
  late RefreshUtilController _refreshController;
  Widget? _statusWidget;

  ///下拉刷新上提加载更多
  CustomFooter functionFooter({bool enable = true}) {
    double _footerHeight =
        enable == false ? 0 : 44.w + MediaQuery.of(context).padding.bottom;
    return CustomFooter(
      height: _footerHeight,
      builder: (context, mode) {
        Widget body = Container();
        if (mode == LoadStatus.idle) {
          body = Text(
            "上拉加载~",
            style: TextStyle(
              fontSize: 15,
            ),
          );
        } else if (mode == LoadStatus.loading) {
          body = CupertinoActivityIndicator();
        } else if (mode == LoadStatus.failed) {
          body = Text(
            "加载失败！点击重试！",
            style: TextStyle(
              fontSize: 15,
            ),
          );
        } else if (mode == LoadStatus.canLoading) {
          body = Text(
            "松手,加载更多!",
            style: TextStyle(
              fontSize: 15,
            ),
          );
        } else if (mode == LoadStatus.noMore) {
          body = Text(
            "没有更多了!",
            style: TextStyle(
              fontSize: 15,
            ),
          );
        } else if (mode == LoadStatus.failed) {
          body = Text(
            "加载失败!",
            style: TextStyle(
              fontSize: 15,
            ),
          );
        } else {
          enable = false;
        }

        return enable == false
            ? Container()
            : Container(
                alignment: Alignment.center,
                height: _footerHeight,
                child: body,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
              );
      },
    );
  }

  void _updateState() {
    if (mounted) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          if (_refreshController.status == RefreshUtilStatus.networkFailure) {
            _statusWidget = RefreshUtilWidget.networkFailurePlaceholder(() {
              if (widget.statusFeedback != null) {
                widget.statusFeedback!();
              } else {
                _refreshController.requestRefresh();
              }
            });
          } else if (_refreshController.status == RefreshUtilStatus.emptyData) {
            _statusWidget = RefreshUtilWidget.emptyDataPlaceholder();
          } else if (_refreshController.status ==
              RefreshUtilStatus.locationFailure) {
            _statusWidget = RefreshUtilWidget.locationFailurePlaceholder(() {
              if (widget.statusFeedback != null) {
                widget.statusFeedback!();
              } else {
                _refreshController.requestRefresh();
              }
            });
          } else {
            _statusWidget = null;
          }

          setState(() {});
        }
      });
    }
  }

  LogoRefreshHeader _functionHeader() {
    double _headerHeight = 88.w;
    return LogoRefreshHeader(
      height: _headerHeight,
      refreshStyle: RefreshStyle.Front,
      initialRefresh: _refreshController.initialRefresh,
    );
  }

  @override
  void initState() {
    super.initState();

    _refreshController = widget.refreshController;
    _refreshController.addListener(() {
      _updateState();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshConfiguration(
      hideFooterWhenNotFull: true,
      skipCanRefresh: true,
      enableBallisticLoad: true,
      enableLoadingWhenFailed: false,
      child: (this.widget.slivers ?? []).length == 0
          ? SmartRefresher(
              controller: _refreshController.refresh,
              enablePullDown: (this.widget.onRefresh ?? null) != null,
              enablePullUp: (this.widget.onLoadMore ?? null) != null,
              // header: MaterialClassicHeader(),
              header: _functionHeader(),
              physics: this.widget.scrollPhysics,
              footer: functionFooter(
                enable: (this.widget.onLoadMore ?? null) != null,
              ),
              onRefresh: this.widget.onRefresh == null
                  ? null
                  : () {
                      if (this.widget.onLoadMore != null) {
                        _refreshController.loadComplete();
                      }
                      _refreshController.status = RefreshUtilStatus.normal;
                      widget.onRefresh!();
                    },
              onLoading: this.widget.onLoadMore,
              child: (_statusWidget ?? null) == null
                  ? this.widget.child
                  : _statusWidget,
              scrollController:
                  (_statusWidget ?? null) == null ? null : _scrollController,
            )
          : SmartRefresher.builder(
              controller: _refreshController.refresh,
              enablePullDown: (this.widget.onRefresh ?? null) != null,
              enablePullUp: (this.widget.onLoadMore ?? null) != null,
              onRefresh: this.widget.onRefresh == null
                  ? null
                  : () {
                      if (this.widget.onLoadMore != null) {
                        _refreshController.loadComplete();
                      }
                      _refreshController.status = RefreshUtilStatus.normal;

                      widget.onRefresh!();
                    },
              onLoading: this.widget.onLoadMore,
              builder: (context, physics) {
                return CustomScrollView(
                  controller: (_statusWidget ?? null) == null
                      ? null
                      : _scrollController,
                  physics: physics,
                  // 0 正常 1 自定义
                  slivers: (_statusWidget ?? null) != null
                      ? [_statusWidget ?? Container()]
                      : this.widget.slivers ?? [],
                );
              },
            ),
    );
  }
}

class RefreshUtilController extends ChangeNotifier {
  late RefreshController refresh;

  final bool initialRefresh;
  late RefreshUtilStatus? _status = RefreshUtilStatus.normal;
  RefreshUtilStatus get status => _status!;
  set status(RefreshUtilStatus s) {
    if (_status != s) {
      _status = s;
      notifyListeners();
    }
  }

  void requestRefresh(
      {bool needMove: true,
      bool needCallback: true,
      Duration duration: const Duration(milliseconds: 500),
      Curve curve: Curves.linear}) {
    this.status = RefreshUtilStatus.normal;
    refresh.requestRefresh(
        needMove: needMove,
        needCallback: needCallback,
        duration: duration,
        curve: curve);
  }

  void requestTwoLevel(
      {Duration duration: const Duration(milliseconds: 300),
      Curve curve: Curves.linear}) {
    refresh.requestTwoLevel(duration: duration, curve: curve);
  }

  void requestLoading(
      {bool needMove: true,
      bool needCallback: true,
      Duration duration: const Duration(milliseconds: 300),
      Curve curve: Curves.linear}) {
    this.status = RefreshUtilStatus.normal;
    refresh.requestLoading(
        needMove: needMove,
        needCallback: needCallback,
        duration: duration,
        curve: curve);
  }

  void refreshCompleted({bool resetFooterState: false}) {
    this.status = RefreshUtilStatus.normal;
    refresh.refreshCompleted(resetFooterState: resetFooterState);
  }

  void twoLevelComplete(
      {Duration duration: const Duration(milliseconds: 500),
      Curve curve: Curves.linear}) {
    refresh.twoLevelComplete(duration: duration, curve: curve);
  }

  void refreshFailed() {
    refresh.refreshFailed();
  }

  void refreshToIdle() {
    refresh.refreshToIdle();
  }

  void loadComplete() {
    this.status = RefreshUtilStatus.normal;
    refresh.loadComplete();
  }

  void loadFailed() {
    refresh.loadFailed();
  }

  void loadNoData() {
    refresh.loadNoData();
  }

  void resetNoData() {
    refresh.resetNoData();
  }

  RefreshUtilController({this.initialRefresh: true}) {
    refresh = RefreshController(initialRefresh: initialRefresh);
  }

  @override
  void dispose() {
    refresh.dispose();
    super.dispose();
  }
}
