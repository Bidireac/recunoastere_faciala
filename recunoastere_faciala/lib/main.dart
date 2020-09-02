import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

void main() => runApp(
      MaterialApp(
        title: 'Aplicatie De Recunoastere Faciala',
        theme: ThemeData(
          primaryColor: Colors.cyan[800],
        ),
        home: FacePage(),
      ),
    );

class FacePage extends StatefulWidget {
  @override
  createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  File _imageFile;
  List<Face> _faces;
  bool isLoading = false;
  ui.Image _image;
  final _picker = ImagePicker();

  _openGallery() async {
    final pickedFile = await _picker.getImage(
      source: ImageSource.gallery,
    );
    _getImageAndDetectFaces(pickedFile);
  }

  _openCamera() async {
    final pickedFile = await _picker.getImage(
      source: ImageSource.camera,
    );
    _getImageAndDetectFaces(pickedFile);
  }

  _getImageAndDetectFaces(pickedFile) async {
    final imageFile = File(pickedFile.path);
    setState(() {
      isLoading = true;
    });
    final image = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector();
    List<Face> faces = await faceDetector.processImage(image);
    if (mounted) {
      setState(() {
        _imageFile = imageFile;
        _faces = faces;
        _loadImage(imageFile);
      });
    }
  }

  _loadImage(file) async {
    final data = await file.readAsBytes();
    final value = await decodeImageFromList(data);
    setState(() {
      _image = value;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Recunoastere Faciala',
          style: TextStyle(
            fontFamily: 'Oxygen',
            color: Colors.grey[50],
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: new AlwaysStoppedAnimation<Color>(Colors.cyan[800]),
              ),
            )
          : (_imageFile == null)
              ? Center(
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Container(
                        child: Image(
                          fit: BoxFit.cover,
                          image: AssetImage('images/background.jpg'),
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Nu a fost selectata nicio imagine',
                          style: TextStyle(
                            fontFamily: 'Pacifico',
                            fontSize: 30,
                            color: Colors.blueGrey[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: FittedBox(
                    child: SizedBox(
                      width: _image.width.toDouble(),
                      height: _image.height.toDouble(),
                      child: CustomPaint(
                        painter: FacePainter(_image, _faces),
                      ),
                    ),
                  ),
                ),
      backgroundColor: Colors.grey[200],
      floatingActionButton: SpeedDial(
        tooltip: 'Alege O Imagine',
        backgroundColor: Colors.cyan[800],
        animatedIcon: AnimatedIcons.menu_close,
        overlayColor: Colors.amber[900],
        overlayOpacity: 0.2,
        curve: Curves.bounceInOut,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add_a_photo),
            label: "Camera",
            labelStyle: TextStyle(
              fontFamily: 'Oxygen',
              color: Colors.cyan[800],
              fontSize: 20,
            ),
            backgroundColor: Colors.deepOrange[900],
            onTap: _openCamera,
          ),
          SpeedDialChild(
            child: Icon(Icons.add_photo_alternate),
            label: "Galerie",
            labelStyle: TextStyle(
              fontFamily: 'Oxygen',
              color: Colors.cyan[800],
              fontSize: 20,
            ),
            backgroundColor: Colors.deepOrange[900],
            onTap: _openGallery,
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final myPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..color = Colors.redAccent[400];

    canvas.drawImage(image, Offset.zero, myPaint);
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], myPaint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}
