import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final File image;
  final String result;
  final double microplasticAmount; // Add this parameter

  ResultScreen({
    required this.image,
    required this.result,
    required this.microplasticAmount, // Ensure this is added
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detection Result"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.file(image, height: 200),
          SizedBox(height: 20),
          Text(result, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _showMicroplasticScale(context);
            },
            child: Text("Show Water Microplastic Amount"),
          ),
        ],
      ),
    );
  }

  void _showMicroplasticScale(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Water Microplastic Level"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Detected Microplastic Amount: ${microplasticAmount.toStringAsFixed(2)} µg/L"),
              SizedBox(height: 10),
              LinearProgressIndicator(
                value: microplasticAmount / 100, // Assuming 100 µg/L as a max scale
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(
                  microplasticAmount < 20 ? Colors.green :
                  microplasticAmount < 50 ? Colors.orange : Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                microplasticAmount < 20 ? "Safe" :
                microplasticAmount < 50 ? "Moderate" : "High Contamination",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: microplasticAmount < 20 ? Colors.green :
                  microplasticAmount < 50 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
