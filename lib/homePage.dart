import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  XFile? _image;
  String _responseBody = '';
  bool isSending = false;

  openCamera() {
    if (_image == null) {
      getImageFromCamera();
    }
  }

  Future<void> getImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      ImageCropper cropper = ImageCropper();
      final croppedImage = await cropper.cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );
      setState(() {
        _image = croppedImage != null ? XFile(croppedImage.path) : null;
      });
    }
  }

  Future<void> sendImage(XFile? imageFile) async {
    if (imageFile == null) return;
    setState(() {
      isSending = true;
    });
    try {
      String base64Image = base64Encode(File(imageFile.path).readAsBytesSync());
      String apiKey = "AIzaSyDtVfNxPqf9DgdLVXWXHWLfcZlAi-jAQh4";
      String requestBody = json.encode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image,
                }
              }
            ]
          }
        ]
      });

      http.Response response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent?key=${apiKey}"),
        headers: {"content-type": "application/json"},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonBody = json.decode(response.body);
        if (jsonBody.containsKey('candidates')) {
          List<dynamic> candidates = jsonBody['candidates'];
          if (candidates.isNotEmpty && candidates[0].containsKey('content')) {
            Map<String, dynamic> content = candidates[0]['content'];
            if (content.containsKey('parts') && content['parts'].isNotEmpty) {
              Map<String, dynamic> parts = content['parts'][0];
              if (parts.containsKey('text')) {
                setState(() {
                  _responseBody = parts['text'];
                  isSending = false;
                });
                print("Image sent Successfully");
                return;
              }
            }
          }
        }
      }
      print("Failed to process image");
    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade50,
        title: Text("Smart Solver",style: TextStyle(
          color: Colors.purple.shade900,
          fontWeight: FontWeight.w600
        ),),
        actions: [
          _image == null
              ? Container()
              : IconButton(
                  onPressed: () {
                    setState(() {
                      _image = null;
                      _responseBody = '';
                    });
                  },
                  icon: Icon(Icons.delete_outline),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _image == null ? openCamera() : sendImage(_image);
        },
        child: Icon(
          _image == null ? Icons.camera_alt : Icons.send,
          color: Colors.purple,
        ),
        tooltip: _image == null ? "Pick Image" : "Send",
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _image == null
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      "Take image to solve the question",
                      style: TextStyle(color: Colors.black45),
                    ),
                  )
                : Image.file(File(_image!.path)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                children: [
                  if (isSending)
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 6,
                          ),
                          CupertinoActivityIndicator(
                            color: Colors.purple,
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            "Solving....",
                            style: TextStyle(color: Colors.black45),
                          )
                        ],
                      ),
                    ),
                  if (_responseBody != '')
                    Container(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.purple.shade300,
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(10))),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        "Solution :",
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 18),
                                      ),
                                    )),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 6,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(_responseBody,style: TextStyle(color: Colors.black54),),
                          ),
                        ],
                      ),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
