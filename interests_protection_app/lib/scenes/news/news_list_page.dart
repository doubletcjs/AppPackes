import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/models/list_page_model.dart';
import 'package:interests_protection_app/models/news_list_model.dart';
import 'package:interests_protection_app/apis/news_api.dart';
// import 'package:interests_protection_app/scenes/news/widgets/news_focus_item.dart';
// import 'package:interests_protection_app/scenes/news/widgets/news_image_item.dart';
// import 'package:interests_protection_app/scenes/news/widgets/news_images_item.dart';
// import 'package:interests_protection_app/scenes/news/widgets/news_top_item.dart';
// import 'package:interests_protection_app/scenes/news/widgets/news_video_item.dart';
import 'package:interests_protection_app/scenes/news/widgets/news_title_item.dart';
import 'package:interests_protection_app/utils/refresh_util.dart';

class NewsListPage extends StatefulWidget {
  final int tag;
  final void Function(String country)? countrySwitch;
  const NewsListPage({
    Key? key,
    required this.tag,
    required this.countrySwitch,
  }) : super(key: key);

  @override
  State<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage>
    with AutomaticKeepAliveClientMixin {
  RefreshUtilController _refreshController =
      RefreshUtilController(initialRefresh: true);

  int _page = 1;
  int _pagesize = 10;

  List<NewsListModel> _dataList = [];

  void _refreshData() {
    _page = 1;
    _refreshController.resetNoData();
    setState(() {});

    _requestNews();
  }

  void _loadMoreData() {
    _page += 1;
    setState(() {});

    _requestNews();
  }

  void _requestNews() {
    void _handleData(dynamic value) {
      ListPageModel _pageModel = ListPageModel.fromJson(value["page"] ?? {});
      List _list = value["items"] ?? [];
      String _country = value["country"] ?? "";
      List<NewsListModel> _newsList = [];
      _list.forEach((element) {
        NewsListModel _listModel = NewsListModel.fromJson(element ?? {});
        if (_listModel.id.length > 0) {
          _newsList.add(_listModel);
        }
      });

      if (_page > 1) {
        _dataList.addAll(_newsList);
      } else {
        _dataList.clear();
        _dataList.addAll(_newsList);
        _refreshController.refreshCompleted();
      }

      if (_pageModel.count == _pageModel.curpage) {
        _refreshController.loadNoData();
      }

      if (_dataList.length == 0) {
        _refreshController.status = RefreshUtilStatus.emptyData;
      }

      setState(() {});

      if (_country.length > 0 && widget.countrySwitch != null) {
        widget.countrySwitch!(_country);
      }
    }

    void _handleError(dynamic error) {
      if (_page > 1) {
        _refreshController.loadFailed();
        _page -= 1;
      } else {
        _refreshController.refreshFailed();
      }

      if (error is Map && error["code"] == -998) {
        _refreshController.status = RefreshUtilStatus.networkFailure;
      } else if (_dataList.length == 0) {
        _refreshController.status = RefreshUtilStatus.emptyData;
      }

      setState(() {});
    }

    if (widget.tag == 1) {
      NewsApi.location(params: {
        "page": _page,
        "pagesize": _pagesize,
      }).then((value) {
        _handleData(value);
      }).catchError((error) {
        _handleError(error);
      });
    } else {
      NewsApi.index(params: {
        "page": _page,
        "pagesize": _pagesize,
        "country": "",
      }).then((value) {
        _handleData(value);
      }).catchError((error) {
        _handleError(error);
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshUtilWidget(
      refreshController: _refreshController,
      onRefresh: _refreshData,
      onLoadMore: _dataList.length < _pagesize ? null : _loadMoreData,
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        padding: EdgeInsets.only(top: 10.w),
        itemBuilder: (context, index) {
          // if (index < 4) {
          //   return const NewsTopItem();
          // }

          // if (index == 6) {
          //   return const NewsImageItem();
          // }

          // if (index == 4) {
          //   return const NewsFocusItem();
          // }

          // if (index == 8) {
          //   return const NewsImagesItem();
          // }

          // if (index == 10) {
          //   return const NewsVideoItem();
          // }

          return NewsTitleItem(listModel: _dataList[index]);
        },
        itemCount: _dataList.length,
      ),
    );
  }
}
