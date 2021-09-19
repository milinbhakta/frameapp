import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:slide_popup_dialog/pill_gesture.dart';

class Pick_Frame extends StatefulWidget {
  /// initial selection for the slider
  final List<String> imgData;
  final int selectedIndex;
  const Pick_Frame({
    Key key,
    @required this.imgData,
    @required this.selectedIndex,
  }) : super(key: key);

  @override
  _Pick_FrameState createState() => _Pick_FrameState();
}

class _Pick_FrameState extends State<Pick_Frame> {
  /// current selection of the slider
  var _initialPosition = 0.0;
  var _currentPosition = 0.0;
  int selectedidx;

  @override
  void initState() {
    super.initState();
    selectedidx = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets +
            EdgeInsets.only(top: deviceHeight / 1.5 + _currentPosition),
        duration: Duration(milliseconds: 100),
        curve: Curves.decelerate,
        child: MediaQuery.removeViewInsets(
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          context: context,
          child: Center(
            child: Container(
              width: deviceWidth,
              height: deviceHeight,
              child: Material(
                color: Theme.of(context).canvasColor,
                elevation: 24.0,
                type: MaterialType.card,
                child: Column(
                  children: <Widget>[
                    PillGesture(
                      pillColor: Colors.blueGrey[200],
                      onVerticalDragStart: _onVerticalDragStart,
                      onVerticalDragEnd: _onVerticalDragEnd,
                      onVerticalDragUpdate: _onVerticalDragUpdate,
                    ),
                    Text(
                      'Select Image:',
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      height: 150.0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                        child: ListView.builder(
                          padding: EdgeInsets.all(5),
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.imgData.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 100,
                              margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 6.0,
                                  color: selectedidx == index
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedidx = index;
                                    });
                                    Navigator.pop(context, selectedidx);
                                  },
                                  child: FittedBox(
                                    child: SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Image.asset(
                                        widget.imgData[index],
                                      ),
                                    ),
                                  )),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: const Radius.circular(20.0),
                    topRight: const Radius.circular(20.0),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onVerticalDragStart(DragStartDetails drag) {
    setState(() {
      _initialPosition = drag.globalPosition.dy;
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails drag) {
    setState(() {
      final temp = _currentPosition;
      _currentPosition = drag.globalPosition.dy - _initialPosition;
      if (_currentPosition < 0) {
        _currentPosition = temp;
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails drag) {
    if (_currentPosition > 100.0) {
      Navigator.pop(context, selectedidx);
      return;
    }
    setState(() {
      _currentPosition = 0.0;
    });
  }
}
