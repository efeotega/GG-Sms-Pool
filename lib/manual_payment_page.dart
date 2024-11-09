import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ManualPaymentPage extends StatefulWidget {
  const ManualPaymentPage({super.key});

  @override
  State<ManualPaymentPage> createState() => _ManualPaymentPageState();
}

class _ManualPaymentPageState extends State<ManualPaymentPage> {
  File? _receiptImage;
  XFile? _webImage; // For storing web image
  final picker = ImagePicker();
  bool isUploading = false;

  final String bankName = "PalmPay";
  final String accountNumber = "8074606365";
  final String accountName = "Patience Etafo";

void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }
  Future<void> _pickReceiptImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = pickedFile; // Use XFile for web
        } else {
          _receiptImage = File(pickedFile.path); // Use File for mobile
        }
      });
    }
  }

  Future<void> _uploadReceipt() async {
    if ((_receiptImage == null && !kIsWeb) || (_webImage == null && kIsWeb)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a receipt image.")),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Reference for storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('receipts')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      String imageUrl;

      if (kIsWeb) {
        // For web, use putData with Uint8List
        final bytes = await _webImage!.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        // For mobile, use putFile
        await storageRef.putFile(_receiptImage!);
      }
      imageUrl = await storageRef.getDownloadURL();

      // Save receipt URL and email to Firestore
      await FirebaseFirestore.instance.collection('receipts').add({
        'imageUrl': imageUrl,
        'userEmail': user.email,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receipt uploaded successfully.")),
      );

      // Clear the selected image
      setState(() {
        _receiptImage = null;
        _webImage = null;
      });
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload receipt: $e")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
           
            const SizedBox(height: 24),
            Text(
              "Bank Details",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
             Row(
              children: [
                Text("Bank Name: $bankName"),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(context, bankName),
                ),
              ],
            ),
            Row(
              children: [
                Text("Account Number: $accountNumber"),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(context, accountNumber),
                ),
              ],
            ),
            Row(
              children: [
                Text("Account Name: $accountName"),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(context, accountName),
                ),
              ],
            ),
            const SizedBox(height:10),
            const Icon(Icons.warning,color:Colors.yellow),
            const Text("Don't add description or remark"),
            const Text("Don't send kobo"),
            const Text("Don't add log or crypto related keywords"),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Receipt"),
              onPressed: _pickReceiptImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blueAccent,
              ),
            ),
            if (_receiptImage != null || _webImage != null) ...[
              const SizedBox(height: 16),
              if (_receiptImage != null) Image.file(_receiptImage!, height: 150),
              if (_webImage != null) Image.network(_webImage!.path, height: 150),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 20,),
            ElevatedButton(
              onPressed: isUploading ? null : _uploadReceipt,
              style: ElevatedButton.styleFrom(
                backgroundColor: isUploading ? Colors.grey : Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isUploading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text(
                      "Submit Receipt",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
