import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ManualPaymentPage extends StatefulWidget {
  const ManualPaymentPage({super.key});

  @override
  State<ManualPaymentPage> createState() => _ManualPaymentPageState();
}

class _ManualPaymentPageState extends State<ManualPaymentPage> {
  File? _receiptImage;
  XFile? _webImage;
  final ImagePicker picker = ImagePicker();
  bool isUploading = false;

  final String bankName = "PalmPay";
  final String accountNumber = "8074606365";
  final String accountName = "Patience Etafo";

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard!")),
    );
  }

  Future<void> _pickReceiptImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = pickedFile;
        } else {
          _receiptImage = File(pickedFile.path);
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

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('receipts/${user.email}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      if (kIsWeb) {
        final bytes = await _webImage!.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        await storageRef.putFile(_receiptImage!);
      }

      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('ggsms_receipts').add({
        'imageUrl': imageUrl,
        'userEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receipt uploaded successfully!")),
      );

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
      appBar: AppBar(
        title: const Text("Manual Payment"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bank Details",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBankDetailRow("Bank Name", bankName),
            _buildBankDetailRow("Account Number", accountNumber),
            _buildBankDetailRow("Account Name", accountName),
            const SizedBox(height: 24),
            _buildWarningSection(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload Receipt"),
              onPressed: _pickReceiptImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.only(left: 15,right:15,top:10,bottom:10),
              ),
            ),
            const SizedBox(height: 16),
            if (_receiptImage != null || _webImage != null) ...[
              _buildImagePreview(),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: isUploading ? null : _uploadReceipt,
              style: ElevatedButton.styleFrom(
                backgroundColor: isUploading ? Colors.grey : Colors.blue,
               padding: const EdgeInsets.only(left: 15,right:15,top:10,bottom:10),
              ),
              child: isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Receipt", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "$label: $value",
            style: const TextStyle(fontSize: 16),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, color: Colors.blue),
          onPressed: () => _copyToClipboard(value),
        ),
      ],
    );
  }

  Widget _buildWarningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text("Important Instructions:", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 8),
        Text("1. Do not add a description or remark."),
        Text("2. Do not send fractional amounts (e.g., kobo)."),
        Text("3. Avoid using log or crypto-related keywords."),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        if (_receiptImage != null)
          Image.file(_receiptImage!, height: 150, fit: BoxFit.cover),
        if (_webImage != null)
          Image.network(_webImage!.path, height: 150, fit: BoxFit.cover),
      ],
    );
  }
}
