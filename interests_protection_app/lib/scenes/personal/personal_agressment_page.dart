import 'package:flutter/material.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';
import 'package:webviewx/webviewx.dart';

class PersonalAgressmentPage extends StatelessWidget {
  const PersonalAgressmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppbarBack(),
        title: Text("用户隐私协议与声明"),
      ),
      body: WebViewX(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            AppBar().preferredSize.height,
        initialContent: 'https://overseas.app.tairnet.com/agreement.html',
        initialSourceType: SourceType.url,
      ),
    );
  }
}
