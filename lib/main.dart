import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:frame_app/Screen/MyCreations.dart';
import 'package:frame_app/Screen/Pick_Frame.dart';
import 'package:get/route_manager.dart';
import 'package:image/image.dart' as IMG;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photofilters/photofilters.dart';
import 'package:save_in_gallery/save_in_gallery.dart';
import 'package:path/path.dart' as path;

class _FramePainter extends CustomPainter {
  const _FramePainter(
      {this.zoom,
      this.offset,
      this.forward,
      this.scaleEnabled,
      this.tapEnabled,
      this.doubleTapEnabled,
      this.longPressEnabled,
      this.frame,
      this.image,
      this.canbgcolor});

  final double zoom;
  final Offset offset;
  final bool forward;
  final bool scaleEnabled;
  final bool tapEnabled;
  final bool doubleTapEnabled;
  final bool longPressEnabled;
  final ui.Image frame;
  final ui.Image image;
  final Color canbgcolor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero) * zoom + offset;
    canvas.drawColor(canbgcolor, BlendMode.color);
    canvas.saveLayer(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            height: size.height,
            width: size.width),
        new Paint());
    canvas.clipRect(Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        height: size.height,
        width: size.width));
    paintImage(
      canvas: canvas,
      scale: zoom,
      image: image,
      fit: BoxFit.contain,
      rect: Rect.fromCenter(
          center: center, height: size.height * zoom, width: size.width * zoom),
    );
    canvas.restore();
    paintImage(
      canvas: canvas,
      scale: 1.0,
      image: frame,
      fit: BoxFit.contain,
      rect: Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          height: size.height,
          width: size.width),
    );
  }

  @override
  bool shouldRepaint(_FramePainter oldPainter) {
    return oldPainter.zoom != zoom ||
        oldPainter.offset != offset ||
        oldPainter.forward != forward ||
        oldPainter.scaleEnabled != scaleEnabled ||
        oldPainter.tapEnabled != tapEnabled ||
        oldPainter.doubleTapEnabled != doubleTapEnabled ||
        oldPainter.longPressEnabled != longPressEnabled ||
        oldPainter.frame != frame ||
        oldPainter.image != image;
  }
}

class FrameApp extends StatefulWidget {
  @override
  FrameAppState createState() => FrameAppState();
}

class FrameAppState extends State<FrameApp> {
  Offset _startingFocalPoint;

  Offset _previousOffset;
  Offset _offset = Offset.zero;

  double _previousZoom;
  double _zoom = 1.0;

  ui.Image _frame;
  ui.Image _image;
  File _img;

  GlobalKey globalKey = new GlobalKey();
  final _imageSaver = ImageSaver();

  bool _imgloading = true;
  bool _infoloading = true;

  bool _forward = true;
  bool _scaleEnabled = true;
  bool _tapEnabled = true;
  bool _doubleTapEnabled = true;
  bool _longPressEnabled = true;

  List<String> frameListData;
  int frameSelectedIndex = 0;
  List<Filter> filters = presetFiltersList;

  @override
  void initState() {
    getFrameListData().then((value) {
      // print('DONE!!!');
      // print('FRAMELISTDATA: $frameListData');
      _loadFrame();
    });
    super.initState();
  }

  void _initGallery() async {
    File gallery = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (gallery != null) {
      setState(() {
        _img = gallery;
        // print('#####IMG:$gallery');
        _loadImage();
      });
    }
  }

  void _initCamera() async {
    File camera = await ImagePicker.pickImage(source: ImageSource.camera);
    if (camera != null) {
      setState(() {
        _img = camera;
        // print('#####IMG:$camera');
        _loadImage();
      });
    }
  }

  Future<void> getFrameListData() async {
    final manifestJson =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final images = json
        .decode(manifestJson)
        .keys
        .where((String key) => key.startsWith('assets/frames/'));
    frameListData = new List<String>.from(images);
  }

  Future getImage(context) async {
    var filename = path.basename(_img.path);
    var image1 = IMG.decodeImage(_img.readAsBytesSync());
    image1 = IMG.copyResize(image1, width: 600);
    Map imagefile = await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => new PhotoFilterSelector(
          title: Text("Photo Filter"),
          image: image1,
          filters: presetFiltersList,
          filename: filename,
          loader: Center(child: CircularProgressIndicator()),
          fit: BoxFit.contain,
        ),
      ),
    );
    if (imagefile != null && imagefile.containsKey('image_filtered')) {
      setState(() {
        _img = imagefile['image_filtered'];
        _loadImage();
      });
    }
  }

  _loadFrame() async {
    await rootBundle.load(frameListData[frameSelectedIndex]).then((bd) async {
      Uint8List lst = new Uint8List.view(bd.buffer);
      await ui.instantiateImageCodec(lst).then((codec) async {
        await codec.getNextFrame().then((frameInfo) {
          setState(() {
            _frame = frameInfo.image;
            // print("Frame instantiated: $_frame");
          });
        });
      });
    });
  }

  _loadImage() async {
    setState(() {
      _imgloading = true;
      _infoloading = false;
    });
    await _img.readAsBytes().then((bd) async {
      Uint8List lst = new Uint8List.view(bd.buffer);
      await ui.instantiateImageCodec(lst).then((codec) async {
        await codec.getNextFrame().then((frameInfo) {
          setState(() {
            _image = frameInfo.image;
            _imgloading = false;
          });
          // print("Image instantiated: $_image");
        });
      });
    });
  }

  Future<void> _pickFrame(BuildContext context) async {
    setState(() {});
    final selectedIndex = await showGeneralDialog(
      context: context,
      pageBuilder: (context, animation1, animation2) {},
      barrierColor: Colors.black.withOpacity(0.7),
      barrierDismissible: false,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation1, animation2, widget) {
        final curvedValue = Curves.easeInOut.transform(animation1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * -300, 0.0),
          child: Opacity(
            opacity: animation1.value,
            child: Pick_Frame(
              imgData: frameListData,
              selectedIndex: frameSelectedIndex,
            ),
          ),
        );
      },
    );

    if (selectedIndex != null) {
      setState(() {
        frameSelectedIndex = selectedIndex;
        _loadFrame();
        // print('frameSelectedIndex $frameSelectedIndex');
      });
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    setState(() {
      _startingFocalPoint = details.focalPoint;
      _previousOffset = _offset;
      _previousZoom = _zoom;
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _zoom = _previousZoom * details.scale;
      // Ensure that item under the focal point stays in the same place despite zooming
      final Offset normalizedOffset =
          (_startingFocalPoint - _previousOffset) / _previousZoom;
      _offset = details.focalPoint - normalizedOffset * _zoom;
    });
  }

  void _handleScaleReset() {
    setState(() {
      _zoom = 1.0;
      _offset = Offset.zero;
    });
  }

  void _handleDirectionChange() {
    setState(() {
      _forward = !_forward;
    });
  }

  Future<bool> _save(BuildContext context) async {
    if (_image != null) {
      RenderRepaintBoundary boundary =
          globalKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage();
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();

      if (Platform.isIOS) {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String appDocPath = appDocDir.path;
        // print('APPDOCDIR: $appDocPath');
        await Directory('$appDocPath/FrameApp').create(recursive: true);
        // write to storage as a filename.png
        File('$appDocPath/FrameApp/Frame_${DateTime.now()}.png')
            .writeAsBytesSync(pngBytes.buffer.asInt8List());
      } else {
        Directory appDocDir = await getExternalStorageDirectory();
        String appDocPath = appDocDir.path;
        // print('APPDOCDIR: $appDocPath');
        await Directory('$appDocPath/FrameApp').create(recursive: true);
        // write to storage as a filename.png
        File('$appDocPath/FrameApp/Frame_${DateTime.now()}.png')
            .writeAsBytesSync(pngBytes.buffer.asInt8List());
      }

      Scaffold.of(context).showSnackBar(SnackBar(
        content: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved!🎉',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
            Text(
              'See your saved creation in "My Creations"',
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
        backgroundColor: Color.fromRGBO(89, 89, 89, 0.7),
        elevation: 9,
      ));

      return true;
    } else {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to Save!😢',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
            Text(
              'Image not Selected!',
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
        backgroundColor: Color.fromRGBO(89, 89, 89, 0.7),
        elevation: 9,
      ));

      return false;
    }
  }

  void _mycreations() async {
    var files;
    if (Platform.isIOS) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      // print('IS Directory: $appDocDir');

      if (Directory("$appDocPath/FrameApp/").existsSync()) {
        files = Directory("$appDocPath/FrameApp/").listSync();
        // print('No of file in EXISTS files: $files');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyCreations(files)),
        );
      } else {
        Directory("$appDocPath/FrameApp/").createSync(recursive: true);
        files = Directory("$appDocPath/FrameApp/").listSync();
        // print('No of file in CREATE files: $files');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyCreations(files)),
        );
      }
    } else {
      Directory appDocDir = await getExternalStorageDirectory();
      String appDocPath = appDocDir.path;

      if (Directory("$appDocPath/FrameApp/").existsSync()) {
        files = Directory("$appDocPath/FrameApp/").listSync();
        // print('No of file in EXISTS files: $files');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyCreations(files)),
        );
      } else {
        Directory("$appDocPath/FrameApp/").createSync(recursive: true);
        files = Directory("$appDocPath/FrameApp/").listSync();
        // print('No of file in CREATE files: $files');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyCreations(files)),
        );
      }
    }
  }

  Widget _threeItemPopup(BuildContext context) => PopupMenuButton(
        itemBuilder: (context) {
          var list = List<PopupMenuEntry<Object>>();
          list.add(PopupMenuItem(
              value: 1,
              child: ListTile(
                leading: Icon(Icons.save),
                title: Text('Save'),
              )));
          list.add(PopupMenuItem(
              value: 2,
              child: ListTile(
                leading: Icon(Icons.photo_album),
                title: Text('My Creations'),
              )));
          return list;
        },
        icon: Icon(
          Icons.more_vert,
        ),
        onCanceled: () {
          // print("You have canceled the menu.");
        },
        onSelected: (value) {
          switch (value) {
            case 1:
              _save(context);
              break;
            case 2:
              _mycreations();
              break;
            default:
              break;
          }
        },
      );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Frame App'),
        actions: [
          Builder(builder: (context) => _threeItemPopup(context)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 7,
            child: !_imgloading
                ? Container(
                    margin: EdgeInsets.all(10),
                    child: FittedBox(
                      child: SizedBox(
                        height: _frame.height.toDouble(),
                        width: _frame.width.toDouble(),
                        child: RepaintBoundary(
                          key: globalKey,
                          child: GestureDetector(
                            onScaleStart:
                                _scaleEnabled ? _handleScaleStart : null,
                            onScaleUpdate:
                                _scaleEnabled ? _handleScaleUpdate : null,
                            onDoubleTap:
                                _doubleTapEnabled ? _handleScaleReset : null,
                            onLongPress: _longPressEnabled
                                ? _handleDirectionChange
                                : null,
                            child: CustomPaint(
                              painter: _FramePainter(
                                zoom: _zoom,
                                offset: _offset,
                                forward: _forward,
                                scaleEnabled: _scaleEnabled,
                                tapEnabled: _tapEnabled,
                                doubleTapEnabled: _doubleTapEnabled,
                                longPressEnabled: _longPressEnabled,
                                frame: _frame,
                                image: _image,
                                canbgcolor: Theme.of(context).canvasColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: !_infoloading
                        ? CircularProgressIndicator()
                        : Text('Image not Selected!!')),
          ),
          Expanded(
              flex: 1,
              child: Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: EdgeInsets.all(5),
                        child: RaisedButton(
                          padding: EdgeInsets.all(15),
                          color: Theme.of(context).primaryColor,
                          onPressed: () {
                            _initCamera();
                          },
                          child: Icon(
                            Icons.photo_camera,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: EdgeInsets.all(5),
                        child: RaisedButton(
                          padding: EdgeInsets.all(15),
                          color: Theme.of(context).primaryColor,
                          onPressed: () {
                            _initGallery();
                          },
                          child: Icon(
                            Icons.photo_library,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: EdgeInsets.all(5),
                        child: RaisedButton(
                          padding: EdgeInsets.all(15),
                          color: Theme.of(context).primaryColor,
                          onPressed: () {
                            _pickFrame(context);
                          },
                          child: Icon(
                            Icons.filter_frames,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // !_imgloading
                    //     ? Expanded(
                    //         flex: 1,
                    //         child: Container(
                    //           margin: EdgeInsets.all(5),
                    //           child: RaisedButton(
                    //             padding: EdgeInsets.all(15),
                    //             color: Theme.of(context).primaryColor,
                    //             onPressed: () {
                    //               getImage(context);
                    //             },
                    //             child: Icon(
                    //               Icons.photo_filter,
                    //               color: Colors.white,
                    //             ),
                    //           ),
                    //         ),
                    //       )
                    //     : Container(),
                  ],
                ),
              )),
          Expanded(
              flex: 1,
              child: Container(
                color: Colors.teal,
              ))
        ],
      ),
    );
  }
}

class MySplashScreen extends StatefulWidget {
  @override
  _MySplashScreenState createState() => new _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen>
    with SingleTickerProviderStateMixin {
  var _visible = true;

  AnimationController animationController;
  Animation<double> animation;

  startTime() async {
    var _duration = new Duration(seconds: 3);
    return new Timer(_duration, navigationPage);
  }

  void navigationPage() {
    Navigator.of(context).pushReplacementNamed('/HomeScreen');
  }

  @override
  void initState() {
    super.initState();
    animationController = new AnimationController(
        vsync: this, duration: new Duration(seconds: 2));
    animation =
        new CurvedAnimation(parent: animationController, curve: Curves.easeOut);

    animation.addListener(() => this.setState(() {}));
    animationController.forward();

    setState(() {
      _visible = !_visible;
    });
    startTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(55, 42, 66, animation.value),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(bottom: 30.0),
                  child: CircularProgressIndicator())
            ],
          ),
          new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Image.asset(
                'assets/loading/loading.gif',
                width: animation.value * 250,
                height: animation.value * 250,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    theme: ThemeData(
      // Define the default brightness and colors.
      brightness: Brightness.light,
      primaryColor: Color.fromRGBO(127, 127, 213, 1),
      accentColor: Color.fromRGBO(145, 234, 228, 1),
      fontFamily: 'Pacifico',
    ),
    darkTheme: ThemeData(
      // Define the default brightness and colors.
      brightness: Brightness.dark,
      primaryColor: Color.fromRGBO(127, 127, 213, 1),
      accentColor: Color.fromRGBO(145, 234, 228, 1),
      fontFamily: 'Pacifico',
    ),
    home: MySplashScreen(),
    routes: <String, WidgetBuilder>{
      '/HomeScreen': (BuildContext context) => new FrameApp(),
    },
    debugShowCheckedModeBanner: false,
  ));
}
