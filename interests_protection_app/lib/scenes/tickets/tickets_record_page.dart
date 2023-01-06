import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:interests_protection_app/apis/tickets_api.dart';
import 'package:interests_protection_app/models/list_page_model.dart';
import 'package:interests_protection_app/models/tickets_list_model.dart';
import 'package:interests_protection_app/scenes/tickets/widgets/tickets_record_item.dart';
import 'package:interests_protection_app/utils/refresh_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class TicketsRecordPage extends StatefulWidget {
  const TicketsRecordPage({Key? key}) : super(key: key);

  @override
  State<TicketsRecordPage> createState() => _TicketsRecordPageState();
}

class _TicketsRecordPageState extends State<TicketsRecordPage> {
  RefreshUtilController _refreshController =
      RefreshUtilController(initialRefresh: true);
  int _page = 1;
  int _pagesize = 10;

  bool _edittingRecord = false;
  List<TicketsListModel> _selectList = [];
  List<TicketsListModel> _dataSources = [];
  String _ticketFilesPath = "";

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
    TicketsApi.getTickets(params: {
      "page": _page,
      "pagesize": _pagesize,
    }).then((value) {
      ListPageModel _pageModel = ListPageModel.fromJson(value["page"] ?? {});
      List _list = value["items"] ?? [];
      List<TicketsListModel> _ticketsList = [];
      _list.forEach((element) {
        TicketsListModel _listModel = TicketsListModel.fromJson(element ?? {});
        if (_listModel.id.length > 0) {
          _ticketsList.add(_listModel);
        }
      });

      if (_page > 1) {
        _dataSources.addAll(_ticketsList);
      } else {
        _dataSources.clear();
        _dataSources.addAll(_ticketsList);
        _refreshController.refreshCompleted();
      }

      if (_pageModel.count == _pageModel.curpage) {
        _refreshController.loadNoData();
      }

      if (_dataSources.length == 0) {
        _refreshController.status = RefreshUtilStatus.emptyData;
      }

      setState(() {});
    }).catchError((error) {
      if (_page > 1) {
        _refreshController.loadFailed();
        _page -= 1;
      } else {
        _refreshController.refreshFailed();
      }
      setState(() {});

      if (error is Map && error["code"] == -998) {
        _refreshController.status = RefreshUtilStatus.networkFailure;
      } else if (_dataSources.length == 0) {
        _refreshController.status = RefreshUtilStatus.emptyData;
      }
    });
  }

  // 删除工单
  void _onDelete() {
    SVProgressHUD.show();

    String _id = "";
    _selectList.forEach((element) {
      if (_id.length == 0) {
        _id = element.id;
      } else {
        _id += ",${element.id}";
      }
    });

    TicketsApi.ticketsDelete(params: {"id": _id}).then((value) {
      _selectList.forEach((select) {
        _dataSources.removeWhere((element) => element.id == select.id);

        var _fileCacheDirectory = Directory(_ticketFilesPath + "/${select.id}");
        if (_fileCacheDirectory.existsSync()) {
          _fileCacheDirectory.deleteSync(recursive: true);
        }
      });

      Future.delayed(Duration(milliseconds: 300), () {
        _selectList.clear();

        if (_dataSources.length == 0) {
          _edittingRecord = false;
          _refreshController.status = RefreshUtilStatus.emptyData;
        }
        setState(() {
          SVProgressHUD.dismiss();
        });
      });
    }).catchError((error) {
      SVProgressHUD.dismiss();

      _edittingRecord = false;
      _selectList.clear();
      setState(() {
        _refreshController.requestRefresh();
      });
    });
  }

  @override
  void initState() {
    super.initState();

    StorageUtils.getUserTicketsPath().then((value) async {
      _ticketFilesPath = value;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.2.w,
        shadowColor: const Color(0xFFF2F2F2),
        title: Text("上报记录"),
        leading: AppbarBack(),
        actions: [
          _edittingRecord == true
              ? Row(
                  children: [
                    MaterialButton(
                      onPressed: () {
                        if (_selectList.length == _dataSources.length) {
                          _selectList.clear();
                        } else {
                          _selectList.clear();
                          for (var i = 0; i < _dataSources.length; i++) {
                            _selectList.add(_dataSources[i]);
                          }
                        }

                        setState(() {});
                      },
                      minWidth: 44.w,
                      height: 44.w,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(44.w / 2),
                      ),
                      child: Text(
                        "全选",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    MaterialButton(
                      onPressed: () {
                        if (_selectList.length == 0) {
                          _edittingRecord = false;
                          setState(() {});
                        } else {
                          _onDelete();
                        }
                      },
                      minWidth: 44.w,
                      height: 44.w,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(44.w / 2),
                      ),
                      child: Text(
                        _selectList.length == 0 ? "取消" : "删除",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ),
                  ],
                )
              : (_dataSources.length == 0
                  ? SizedBox()
                  : MaterialButton(
                      onPressed: () {
                        _edittingRecord = true;
                        setState(() {});
                      },
                      minWidth: 44.w,
                      height: 44.w,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(44.w / 2),
                      ),
                      child: Text(
                        "管理",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    )),
          SizedBox(width: 11.w),
        ],
      ),
      body: RefreshUtilWidget(
        refreshController: _refreshController,
        onRefresh: _refreshData,
        onLoadMore: _dataSources.length < _pagesize ? null : _loadMoreData,
        child: ListView.builder(
          physics: BouncingScrollPhysics(),
          shrinkWrap: true,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          itemBuilder: (context, index) {
            TicketsListModel _model = _dataSources[index];
            return TicketsRecordItem(
              edittingRecord: _edittingRecord,
              model: _model,
              selected: _selectList.contains(_model),
              selectAction: () {
                if (_selectList.contains(_model)) {
                  _selectList.remove(_model);
                } else {
                  _selectList.add(_model);
                }
                setState(() {});
              },
              detailAction: () {
                _model.unread = false;
                setState(() {});
              },
            );
          },
          itemCount: _dataSources.length,
        ),
      ),
    );
  }
}
