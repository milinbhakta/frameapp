import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share/share.dart';

class MyCreations extends StatefulWidget {
  MyCreations(this.files);
  final List<FileSystemEntity> files;
  @override
  _MyCreationsState createState() => _MyCreationsState();
}

class _MyCreationsState extends State<MyCreations>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    // print('Files in Creations: ${widget.files.length}');
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 220.0,
            floating: true,
            pinned: true,
            snap: false,
            elevation: 50,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text('My Creations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    )),
                background: Image.network(
                  'https://images.pexels.com/photos/443356/pexels-photo-443356.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
                  fit: BoxFit.cover,
                )),
          ),
          SliverGrid(
            delegate:
                SliverChildBuilderDelegate((BuildContext context, int index) {
              Image img = Image.file(
                File(widget.files[index].path),
                fit: BoxFit.fitHeight,
              );
              double h = img.height;
              double w = img.width;

              return InkWell(
                onTap: () async {
                  showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        titlePadding: EdgeInsets.all(10),
                        title: img,
                        elevation: 8,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              FlatButton(
                                onPressed: () {
                                  // print(
                                  //     'IMG PATH ****${widget.files[index].path}');
                                  Share.shareFiles(
                                      ['${widget.files[index].path}']);
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Icon(Icons.share),
                                    Text('Share')
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      );
                    },
                  );
                  // print('Index of image: $index');
                },
                child: Container(
                  child: FittedBox(
                    child: SizedBox(height: h, width: w, child: img),
                  ),
                ),
              );
            }, childCount: widget.files.length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
          )
        ],
      ),
    );
  }
}
