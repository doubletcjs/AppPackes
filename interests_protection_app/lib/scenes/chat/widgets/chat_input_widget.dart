import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ChatInputState {
  none,
  text,
  file,
}

class ChatInputWidget extends StatefulWidget {
  final ChatInputController? controller;
  final void Function(String content)? sendTextHandler;
  final void Function(int index)? sendFileHandler;
  final void Function()? inputShowFeedback;
  final bool? customer;
  const ChatInputWidget({
    Key? key,
    required this.controller,
    required this.customer,
    this.sendTextHandler,
    this.sendFileHandler,
    this.inputShowFeedback,
  }) : super(key: key);

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  late ChatInputController? _controller;
  FocusNode _focusNode = FocusNode();
  TextEditingController _editingController = TextEditingController();
  List<String> _fileTypeIcons = [
    "images/assistant_gallery@2x.png",
    "images/assistant_camera@2x.png",
    "images/assistant_file@2x.png",
  ];

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? ChatInputController();
    _controller!.addListener(() {
      if (_controller!.inputState == ChatInputState.none) {
        FocusScope.of(context).requestFocus(FocusNode());
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _editingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: const Color(0xFFF6F6F6),
            padding: EdgeInsets.only(
              left: 11.w,
              right: 17.w,
              top: 8.w,
              bottom: 8.w,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10.w),
                      border: Border.all(
                        width: 0.5.w,
                        color: const Color(0xFFE8E8E8),
                      ),
                    ),
                    constraints: BoxConstraints(minHeight: 40.w),
                    padding: EdgeInsets.only(
                      left: 19.w,
                      right: 19.w,
                      top: 10.w,
                      bottom: 10.w,
                    ),
                    child: TextField(
                      minLines: 1,
                      maxLines: 5,
                      controller: _editingController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: const Color(0xFF313131),
                        fontSize: 15.sp,
                      ),
                      textInputAction: TextInputAction.send,
                      keyboardType: TextInputType.text,
                      onSubmitted: (value) {
                        if (value.trim().length > 0 &&
                            widget.sendTextHandler != null) {
                          widget.sendTextHandler!(value);
                        }

                        if (mounted) {
                          _editingController.text = "";
                          setState(() {});
                        }

                        FocusScope.of(context).requestFocus(_focusNode);
                      },
                      onTap: () {
                        _controller!.inputState = ChatInputState.text;
                        setState(() {});

                        if (widget.inputShowFeedback != null) {
                          widget.inputShowFeedback!();
                        }
                      },
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: widget.customer == true ? "请输入您的咨询" : "",
                        hintStyle: TextStyle(
                          color: const Color(0xFFE5E5E5),
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 30.w,
                  height: 30.w,
                  margin: EdgeInsets.only(left: 17.w),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        "images/assistant_file_select@2x.png",
                      ),
                    ),
                  ),
                  child: MaterialButton(
                    onPressed: () {
                      if (_controller!.inputState != ChatInputState.file) {
                        FocusScope.of(context).requestFocus(FocusNode());

                        Future.delayed(Duration(milliseconds: 200), () {
                          _controller!.inputState = ChatInputState.file;
                          setState(() {});
                        });
                      } else if (_controller!.inputState ==
                          ChatInputState.file) {
                        _controller!.inputState = ChatInputState.text;
                        setState(() {});

                        Future.delayed(Duration(milliseconds: 0), () {
                          FocusScope.of(context).requestFocus(_focusNode);
                        });
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40.w / 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _controller!.inputState == ChatInputState.file && mounted
              ? Container(
                  height: 218.w,
                  color: const Color(0xFFF6F6F6),
                  padding: EdgeInsets.fromLTRB(24.w, 14.w, 24.w, 14.w),
                  alignment: Alignment.topLeft,
                  child: Wrap(
                    spacing: 24.w,
                    runSpacing: 24.w,
                    children:
                        List.generate(_fileTypeIcons.length, (index) => index)
                            .map((index) {
                      return Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(10.w),
                        ),
                        alignment: Alignment.center,
                        child: MaterialButton(
                          onPressed: () {
                            if (widget.sendFileHandler != null) {
                              widget.sendFileHandler!(index);
                            }

                            if (widget.inputShowFeedback != null) {
                              widget.inputShowFeedback!();
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.w),
                          ),
                          child: Center(
                            child: Image.asset(
                              _fileTypeIcons[index],
                              width: 30.w,
                              height: 24.w,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : SizedBox(),
          Container(
            height: MediaQuery.of(context).padding.bottom,
            color: const Color(0xFFF6F6F6),
          ),
        ],
      ),
    );
  }
}

class ChatInputController extends ChangeNotifier {
  ChatInputState inputState = ChatInputState.none;

  void hideKeyboard() {
    inputState = ChatInputState.none;
    notifyListeners();
  }

  void showKeyboard() {
    inputState = ChatInputState.text;
    notifyListeners();
  }
}
