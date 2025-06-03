// lib/screens/test/firebase_test_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestScreen extends StatefulWidget {
  @override
  _FirebaseTestScreenState createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Testing Firebase Connection...';
  
  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }
  
  Future<void> _testFirebaseConnection() async {
    try {
      // Test Firestore connection
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection')
          .set({'timestamp': FieldValue.serverTimestamp()});
      
      setState(() {
        _status = '✅ Firebase connected successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Firebase connection failed: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Test')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _status.contains('✅') ? Icons.check_circle : Icons.error,
                size: 64,
                color: _status.contains('✅') ? Colors.green : Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}