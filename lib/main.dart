import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Microplastic Detector',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: MicroplasticDetectionScreen(),
    );
  }
}

class MicroplasticDetectionScreen extends StatefulWidget {
  @override
  _MicroplasticDetectionScreenState createState() =>
      _MicroplasticDetectionScreenState();
}

class _MicroplasticDetectionScreenState
    extends State<MicroplasticDetectionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  File? _image;
  String _result = "No analysis yet";
  Interpreter? _interpreter;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    // Force Portrait Mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
    _initializeCamera();
    _loadModel();
  }

  // Initialize the camera
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController =
          CameraController(_cameras![0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  // Load TFLite model
  Future<void> _loadModel() async {
    try {
      final modelPath = "assets/model.tflite";
      _interpreter = await Interpreter.fromAsset(modelPath);
      print("Model Loaded Successfully");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  // Capture image using camera
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final XFile file = await _cameraController!.takePicture();
    setState(() {
      _image = File(file.path);
    });

    _runInference();
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _runInference();
    }
  }

  // Run inference on the image
  Future<void> _runInference() async {
    if (_image == null || _interpreter == null) return;

    try {
      var input = await _preprocessImage(_image!);
      var output = List.filled(1, 0).reshape([1, 1]);

      _interpreter!.run(input, output);

      setState(() {
        _result = "Detection Result: ${output[0][0] > 0.5 ? "Microplastics Detected" : "No Microplastics"}";
      });
    } catch (e) {
      print("Error running inference: $e");
    }
  }

  // Placeholder for Image Preprocessing
  Future<List<List<List<List<double>>>>> _preprocessImage(File image) async {
    return [
      [
        [
          [0.0]
        ]
      ]
    ];
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Microplastic Detector"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.blueAccent.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                flex: 2,
                child: _isCameraInitialized
    ? Transform.rotate(
        angle: 1.5708, // 90 degrees in radians (π/2)
        child: CameraPreview(_cameraController!),
      )
    : Center(child: CircularProgressIndicator()),

              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _image != null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundImage: FileImage(_image!),
                            )
                          : Icon(Icons.camera_alt, size: 50, color: Colors.white70),
                      SizedBox(height: 10),
                      Text(
                        _result,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _captureImage,
                            icon: Icon(Icons.camera),
                            label: Text("Capture"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.image),
                            label: Text("Gallery"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
