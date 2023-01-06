import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class NewsVideoItem extends StatefulWidget {
  const NewsVideoItem({Key? key}) : super(key: key);

  @override
  State<NewsVideoItem> createState() => _NewsVideoItemState();
}

class _NewsVideoItemState extends State<NewsVideoItem> {
  late VideoPlayerController _controller;
  bool _loadingVideo = true;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.network(
        "https://flv2.bn.netease.com/5e989524a28095aa0789f4c42fb4e92f10577a8e70e05954c420dfbe4968fa7959ed620cced1acfc4d8a3fc8d67e9dd7f5ca65a4135f8704c42c4cbeb08138923b03acad5c8ee3a2d5528d9d58593d98cc4af8e5c4a7e24cbe80dabab2b3674a369373c78a623c50add3068393944389bc0eef2bfed2341a.mp4");
    _controller.initialize()
      ..whenComplete(() {
        _loadingVideo = false;
        setState(() {});
      });
    _controller.setLooping(false);
    _controller.addListener(() {
      if (_controller.value.duration.inMilliseconds ==
          _controller.value.position.inMilliseconds) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () {},
      padding: EdgeInsets.fromLTRB(27.w, 16.w, 20.w, 16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        children: _loadingVideo == true
            ? [
                SizedBox(
                  height: 188.w,
                  child: Center(
                    child: SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              ]
            : [
                Text(
                  "美国曾经计划用核弹打击中国113座城市，其中有你的家乡美国曾经计划用核弹打击中国113座城市，其中有你的家乡",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                SizedBox(height: 8.w),
                SizedBox(
                  height: 188.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }

                          setState(() {});
                        },
                        child: IgnorePointer(
                          child: Container(
                            color: Colors.black,
                            child: AspectRatio(
                              aspectRatio: 655.w / 376.w,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        ),
                      ),
                      _controller.value.duration.inMilliseconds ==
                                  _controller.value.position.inMilliseconds &&
                              _controller.value.position.inMilliseconds > 0
                          ? MaterialButton(
                              onPressed: () {
                                _controller.seekTo(Duration.zero);
                                _controller.play();
                                setState(() {});
                              },
                              color: const Color(0x7F000000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.w),
                              ),
                              padding: EdgeInsets.only(left: 16.w, right: 17.w),
                              height: 41.w,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    "images/news_replay@2x.png",
                                    width: 16.w,
                                    height: 16.w,
                                  ),
                                  SizedBox(width: 12.w),
                                  Text(
                                    "重新播放",
                                    style: TextStyle(
                                      color: const Color(0xFFFFFFFF),
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _controller.value.isPlaying == false
                              ? IgnorePointer(
                                  child: Image.asset(
                                    "images/news_play@2x.png",
                                    width: 39.w,
                                    height: 39.w,
                                  ),
                                )
                              : SizedBox(),
                    ],
                  ),
                ),
              ],
      ),
    );
  }
}
