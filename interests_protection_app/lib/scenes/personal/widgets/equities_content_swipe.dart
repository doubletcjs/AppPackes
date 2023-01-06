import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';

class EquitiesContentSwipe extends StatefulWidget {
  final int levelIndex;
  final List equities;
  final void Function(int id, int index)? contentIdFeedback;
  final int? jumpContentId;
  EquitiesContentSwipe({
    Key? key,
    required this.levelIndex,
    required this.equities,
    this.jumpContentId,
    this.contentIdFeedback,
  }) : super(key: key);

  @override
  State<EquitiesContentSwipe> createState() => _EquitiesContentSwipeState();
}

class _EquitiesContentSwipeState extends State<EquitiesContentSwipe> {
  final SwiperController _swiperController = SwiperController();
  int _currentIndex = 0;
  final Map _textColorMap = {
    0: const Color(0xFFF7D8B2),
    1: const Color(0xFF713C1C),
    2: const Color(0xFF42528F),
    3: const Color(0xFF5A5A5A),
  };

  final Map _gradientColorMap = {
    0: [const Color(0xFFE3B388), const Color(0xFFF7D8B2)], //SVIP
    1: [const Color(0xFFEBD6A2), const Color(0xFFF0DFB4)], //VIP
    2: [const Color(0xFFABC5ED), const Color(0xFFE6EFFA)], //普通会员
    3: [const Color(0xFFC7C7C7), const Color(0xFFF2F2F2)], //未实名认证
  };

  final Map _gradientDisableColorMap = {
    0: [
      const Color(0xFFE3B388).withOpacity(0.5),
      const Color(0xFFF7D8B2).withOpacity(0.5)
    ], //SVIP
    1: [
      const Color(0xFFEBD6A2).withOpacity(0.5),
      const Color(0xFFF0DFB4).withOpacity(0.5)
    ], //VIP
    2: [
      const Color(0xFFABC5ED).withOpacity(0.5),
      const Color(0xFFE6EFFA).withOpacity(0.5)
    ], //普通会员
    3: [
      const Color(0xFFC7C7C7).withOpacity(0.5),
      const Color(0xFFF2F2F2).withOpacity(0.5)
    ], //未实名认证
  };

  final Map<int, Color> _equitiesTextColorMap = {
    0: const Color(0xFF541E04), //SVIP
    1: const Color(0xFF713C1C), //VIP
    2: const Color(0xFF42528F), //普通会员
    3: const Color(0xFF5A5A5A), //未实名认证
  };

  int _currentId = 0;
  bool _tappingCard = false;
  Widget _swipeCard(int index) {
    Color _textColor = _textColorMap[widget.levelIndex];
    return GestureDetector(
      onTap: () {
        _currentIndex = index;
        _currentId = widget.equities[index]["id"];
        _tappingCard = true;
        setState(() {});

        if (widget.contentIdFeedback != null) {
          widget.contentIdFeedback!(_currentId, _currentIndex);
        }

        _swiperController.move(index);
        Future.delayed(Duration(milliseconds: 300), () {
          _tappingCard = false;
          setState(() {});
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
              height: _currentId == widget.equities[index]["id"]
                  ? (20.w * 0.8)
                  : 20.w),
          Transform.scale(
            scale: _currentId == widget.equities[index]["id"] ? 1.2 : 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _currentId == widget.equities[index]["id"]
                          ? _gradientColorMap[widget.levelIndex]
                          : _gradientDisableColorMap[widget.levelIndex],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                    borderRadius: BorderRadius.circular(36.w / 2),
                  ),
                ),
                Image.asset(
                  "images/equities/" + widget.equities[index]["icon"],
                  width: 20.w,
                  height: 21.w,
                  color: _equitiesTextColorMap[widget.levelIndex]!
                      .withOpacity(_currentId == widget.equities[index]["id"]
                          ? 1
                          : (widget.levelIndex == 0
                              ? 1
                              : widget.levelIndex == 3
                                  ? 0.4
                                  : 0.5)),
                ),
              ],
            ),
          ),
          SizedBox(
              height: _currentId == widget.equities[index]["id"]
                  ? (3.w * 2.2)
                  : 3.w),
          Text(
            widget.equities[index]["name"],
            style: TextStyle(
              fontSize: 10.sp,
              color: _currentId == widget.equities[index]["id"]
                  ? _textColor
                  : _textColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant EquitiesContentSwipe oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.jumpContentId != null && _currentId != widget.jumpContentId) {
      _currentId = widget.jumpContentId ?? 0;
      _currentIndex =
          widget.equities.indexWhere((element) => element["id"] == _currentId);
      _tappingCard = true;
      _swiperController.move(_currentIndex);

      Future.delayed(Duration(milliseconds: 300), () {
        _tappingCard = false;
      });
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66.w + 25.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Swiper(
            itemBuilder: (context, index) {
              return _swipeCard(index);
            },
            viewportFraction: 0.2,
            itemCount: widget.equities.length,
            physics: BouncingScrollPhysics(),
            loop: false,
            index: _currentIndex,
            controller: _swiperController,
            onIndexChanged: (value) {
              if (_tappingCard == false) {
                _currentIndex = value;
                setState(() {});

                if (widget.contentIdFeedback != null) {
                  widget.contentIdFeedback!(
                      widget.equities[_currentIndex]["id"], _currentIndex);
                }
              }
            },
          ),
          Positioned(
            bottom: -5.5.w,
            child: Image.asset(
              "images/equities_up@2x.png",
              width: 21.w,
              height: 11.w,
            ),
          ),
        ],
      ),
    );
  }
}
