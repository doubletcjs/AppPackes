import 'package:file_preview/file_preview.dart';
import 'package:flutter/material.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class FilePreviewPage extends StatefulWidget {
  final String title;
  final String localPath;

  const FilePreviewPage(
      {Key? key, required this.localPath, required this.title})
      : super(key: key);

  @override
  _FilePreviewPageState createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends State<FilePreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        bottom: true,
        child: FilePreviewWidget(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.bottom -
              AppBar().preferredSize.height -
              MediaQuery.of(context).padding.top,
          path: widget.localPath,
          callBack: FilePreviewCallBack(onShow: () {
            print("文件打开成功");
          }, onDownload: (progress) {
            print("文件下载进度$progress");
          }, onFail: (code, msg) {
            utilsToast(msg: "$msg");
          }),
        ),
      ),
    );
  }
}
