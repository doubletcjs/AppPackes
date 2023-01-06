import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class DirectionsDetailPage extends StatefulWidget {
  final String detailUrl;
  const DirectionsDetailPage({super.key, required this.detailUrl});

  @override
  State<DirectionsDetailPage> createState() => _DirectionsDetailPageState();
}

class _DirectionsDetailPageState extends State<DirectionsDetailPage> {
  String _title = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        leading: AppbarBack(),
        title: Text("$_title"),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: Uri.parse(widget.detailUrl)),
        onTitleChanged: (controller, title) {
          _title = title ?? "";
          setState(() {});
        },
      ),
    );
  }
}
