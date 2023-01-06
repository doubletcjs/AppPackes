import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/utils/widgets/image_picker.dart';
import 'package:interests_protection_app/utils/widgets/photo_view_gallery.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class CommunityImagePicker extends StatefulWidget {
  final void Function(List<File> imageFileList)? feedback;
  final bool? cleanReset;
  const CommunityImagePicker({
    super.key,
    this.feedback,
    this.cleanReset,
  });

  @override
  State<CommunityImagePicker> createState() => _CommunityImagePickerState();
}

class _CommunityImagePickerState extends State<CommunityImagePicker> {
  List<File> _imageFileList = [];
  List<String> _imageBase64List = [];
  List<Widget> _imageWidgetList = [];
  int _maxImageCount = 9;

  // 位置顺序
  void _handleReorder(
    int oldIndex,
    int newIndex,
  ) {
    List<Widget> _widgetList = List.from(_imageWidgetList);
    final widgetElement = _widgetList.removeAt(oldIndex);
    _widgetList.insert(newIndex, widgetElement);

    _imageWidgetList = _widgetList;

    List<File> _dataList = List.from(_imageFileList);
    final dataElement = _dataList.removeAt(oldIndex);
    _dataList.insert(newIndex, dataElement);

    _imageFileList = _dataList;

    List<String> _base64List = List.from(_imageBase64List);
    final base64Element = _base64List.removeAt(oldIndex);
    _base64List.insert(newIndex, base64Element);

    _imageBase64List = _base64List;

    setState(() {
      if (widget.feedback != null) {
        widget.feedback!(_imageFileList);
      }
    });
  }

  // 图片选择
  void _imagePicker() {
    FocusScope.of(context).requestFocus(FocusNode());

    // 图片处理
    void _handleAssetFile(List<File> list) {
      if (list.length == 0) {
        return;
      }

      SVProgressHUD.show();
      for (var i = 0; i < list.length; i++) {
        File element = list[i];
        File? _existMedia = _imageFileList
            .firstWhereOrNull((media) => media.path == element.path);
        if (_existMedia == null) {
          _imageFileList.add(element);

          List<int> _imageData = File(element.path).readAsBytesSync();
          String _imageBase64 = base64Encode(_imageData);
          _imageBase64List.add(_imageBase64);

          _imageWidgetList.add(ClipRRect(
            borderRadius: BorderRadius.circular(10.w),
            child: Image.memory(
              base64Decode(_imageBase64),
              fit: BoxFit.cover,
            ),
          ));
        }

        if (i == list.length - 1) {
          if (widget.feedback != null) {
            widget.feedback!(_imageFileList);
          }
          setState(() {
            Future.delayed(Duration(milliseconds: 300), () {
              SVProgressHUD.dismiss();
            });
          });
        }
      }
    }

    void _pickAction(int index) {
      if (index == 1) {
        // 图库库
        ImagePicker.pick(context,
                count: _maxImageCount - _imageWidgetList.length)
            .then((value) {
          if (value.length > 0) {
            _handleAssetFile(value);
          }
        });
      } else if (index == 0) {
        // 拍照
        ImagePicker.openCamera(context).then((value) {
          if (value.length > 0) {
            _handleAssetFile(value);
          }
        });
      }
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              child: const Text("拍照"),
              onPressed: () {
                Navigator.pop(context);
                _pickAction(0);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("从手机相册选择"),
              onPressed: () {
                Navigator.pop(context);
                _pickAction(1);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text("取消"),
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  bool _resetAction = false;
  @override
  void didUpdateWidget(covariant CommunityImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.cleanReset ?? false) == true && _resetAction == false) {
      _resetAction = true;
      _imageBase64List.clear();
      _imageFileList.clear();
      _imageWidgetList.clear();

      Future.delayed(Duration(milliseconds: 500), () {
        _resetAction = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _imageFileList.length == 0
        ? Row(
            children: [
              MaterialButton(
                onPressed: () {
                  _imagePicker();
                },
                minWidth: 24.w,
                height: 24.w,
                padding: EdgeInsets.zero,
                child: Image.asset(
                  "images/post_image@2x.png",
                  width: 24.w,
                  height: 24.w,
                ),
              ),
            ],
          )
        : ReorderableGridView.count(
            onReorder: (oldIndex, newIndex) {
              _handleReorder(oldIndex, newIndex);
            },
            crossAxisCount: 3,
            childAspectRatio: 91.w / 88.w,
            mainAxisSpacing: 10.w,
            crossAxisSpacing: 10.w,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false,
            children: List.generate(_imageWidgetList.length, (index) => index)
                .map((index) {
              return SizedBox(
                key: ValueKey("ValueKey_$index"),
                width: 91.w,
                height: 88.w,
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());

                    PhotoViewGalleryPage.show(
                      context,
                      PhotoViewGalleryPage(
                        images: _imageBase64List,
                        initIndex: index,
                        deleteAction: (removIndex) {
                          _imageFileList.removeAt(removIndex);
                          _imageWidgetList.removeAt(removIndex);
                          _imageBase64List.removeAt(removIndex);
                          setState(() {});
                        },
                      ),
                    );
                  },
                  child: _imageWidgetList[index],
                ),
              );
            }).toList(),
            dragWidgetBuilder: (index, child) {
              return SizedBox(
                key: ValueKey("MovingValueKey"),
                width: 91.w,
                height: 88.w,
                child: _imageWidgetList[index],
              );
            },
            footer: _imageWidgetList.length == _maxImageCount
                ? []
                : [
                    Container(
                      width: 91.w,
                      height: 88.w,
                      key: ValueKey("CreationValueKey"),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              "images/community_publish_image@2x.png"),
                        ),
                        borderRadius: BorderRadius.circular(10.w),
                      ),
                      child: MaterialButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.w),
                        ),
                        onPressed: () {
                          _imagePicker();
                        },
                      ),
                    ),
                  ],
          );
  }
}
