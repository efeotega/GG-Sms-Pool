import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gg_sms_pool/daisy_services.dart';
import 'package:gg_sms_pool/daisy_sms_proxy.dart';
import 'package:gg_sms_pool/home_page.dart';
import 'package:gg_sms_pool/number_history_page.dart';
import 'package:gg_sms_pool/utils.dart';

class USNumbersPage extends StatefulWidget {
  const USNumbersPage({super.key});

  @override
  _USNumbersPageState createState() => _USNumbersPageState();
}

class _USNumbersPageState extends State<USNumbersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedService = 'None';

  TextEditingController serviceController = TextEditingController();
  String _selectedCode = '';
  String? selectedService = "";
  bool shouldShowServiceDropdown = false;
  bool isLoading = false;

  String? selectedCountry = "United States";

  Map<String, Map<String, int>> priceData = {};
  String displayedPrice = '';
  String _response = '';
  List<Service> _filteredServices = services;

  void _filterServices(String query) {
    setState(() {
      _filteredServices = services
          .where((service) =>
              service.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> savePurchasedNumber(
      String number, String service, String orderId) async {
    try {
      // Get the current logged-in user
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User is not logged in.");
      }

      // Reference to the Firestore document
      final userRef = FirebaseFirestore.instance
          .collection('ggsms_users')
          .doc(user.email)
          .collection('purchased_numbers')
          .doc();

      // Save the number and date
      await userRef.set({
        'number': number,
        'service': service,
        'server': "daisysms",
        'orderId': orderId,
        "status": 1,
        'price': displayedPrice,
        'date': FieldValue.serverTimestamp(),
      });

      print("Number saved successfully in Firestore.");
    } catch (e) {
      print("Failed to save number: $e");
    }
  }

  void showStringInDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Message'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void loadPricingDataExcludeSMSPool() async {
    setState(() {
      isLoading = true;
    });

    var priceDataForNonSMSPool = await fetchPriceData();

    setState(() {
      priceData = priceDataForNonSMSPool;
      isLoading = false;
    });
  }

  Future<Map<String, Map<String, int>>> fetchPriceData() async {
    final priceData = <String, Map<String, int>>{};

    try {
      // Fetch all documents in the "prices" collection
      final priceCollection = await FirebaseFirestore.instance
          .collection('ggsms_prices_daisysms')
          .get();

      // Iterate through each document
      for (var doc in priceCollection.docs) {
        final countryName = doc['name'] as String?;
        final servicePrices = doc['prices'] as Map<String, dynamic>?;

        if (countryName != null && servicePrices != null) {
          // Convert dynamic map to a Map<String, int>, handling nested maps
          final priceMap = _parsePriceMap(servicePrices);
          priceData[countryName] = priceMap;
        } else {
          print(
              "Skipping document with invalid country name or prices: ${doc.id}");
        }
      }
    } catch (e) {
      print("Error fetching price data: $e");
    }

    return priceData;
  }

  Map<String, int> _parsePriceMap(Map<String, dynamic> data) {
    final parsedMap = <String, int>{};

    data.forEach((key, value) {
      if (value is int) {
        parsedMap[key] = value;
      } else if (value is Map<String, dynamic>) {
        // If value is a nested map, recursively parse it
        parsedMap.addAll(_parsePriceMap(value));
      } else {
        print("Skipping invalid value for key $key: $value");
      }
    });

    return parsedMap;
  }

  @override
  void initState() {
    super.initState();
    serviceController.addListener(() {
      _filterServices(serviceController.text);
    });
    loadPricingDataExcludeSMSPool();
  }

  void _onServiceChanged(String? value, String code) {
    setState(() {
      selectedService = value;
      _selectedService = value!;
      serviceController.text = value;
      shouldShowServiceDropdown = false;
      _searchController.text = value;
      _selectedCode = code;
    });
    if (value == "" || value == null) {
      setState(() {
        displayedPrice = '';
      });
    }

    if (selectedCountry != null && selectedService != null) {
      // Set the displayed price based on the selected country and service
      setState(() {
        final countryPrices = priceData[selectedCountry] ?? {};
        displayedPrice =
            (countryPrices[selectedService] ?? countryPrices['default'] ?? 1900)
                .toString();

        // displayedPrice =
        //     '₦${priceData[selectedCountry]?[value] ?? priceData[selectedService]!['default']}';
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error')));
    }
  }

  Future<bool> deductBalance(String country, String service) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User is not logged in.");
        return false;
      }

      // Fetch the user's current balance
      final userDocRef =
          FirebaseFirestore.instance.collection('ggsms_users').doc(user.email);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        print("User document not found.");
        return false;
      }

      // Get the user's current balance
      final int currentBalance = userDoc.data()?['balance'] ?? 0;

      // Fetch the price based on country and service, default to 1500 if not found
      final int price = priceData[country]?[service] ??
          priceData[country]?['default'] ??
          1900;

      // Check if user has enough balance
      if (currentBalance < price) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Insufficient balance. Current balance: $currentBalance, Required: $price"),
          backgroundColor: Colors.red,
        ));
        return false;
      }

      // Calculate the new balance
      final int newBalance = currentBalance - price;

      // Update the balance in Firestore
      await userDocRef.update({'balance': newBalance});

      print("Balance deducted successfully. New balance: $newBalance");
      return true;
    } catch (e) {
      print("Error deducting balance: $e");
      return false;
    }
  }

 Future<void> _buyService() async {
  if (isLoading) return;

  setState(() {
    isLoading = true;
  });

  try {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Please wait..."),
      backgroundColor: Colors.blue,
    ));

    // Deduct balance
    final balanceDeducted = await deductBalance("United States", _selectedService);
    if (!balanceDeducted) {
      throw Exception("Failed to deduct balance.");
    }

    if (_selectedCode.isEmpty) {
      throw Exception("No service selected!");
    }

    final proxy = DaisySMSProxy('https://daisy-proxy.onrender.com');
    final result = await proxy.getNumber(
      apiKey: 'X8PiPQWlxSKYSNcOOWBwYOaze6hgkZ',
      action: 'getNumber',
      service: _selectedCode,
      maxPrice: 1.5,
    );

    if (result['statusCode'] != 200) {
      await refundBalance(_selectedService);
      throw Exception("Error: ${result['statusCode']}");
    }

    final responseBody = result['body'].trim();
    if (responseBody.startsWith('ACCESS_NUMBER')) {
      final parts = responseBody.split(':');
      if (parts.length >= 3) {
        final String id = parts[1];
        final String phoneNumber = parts[2];
        await savePurchasedNumber(phoneNumber, _selectedService, id);

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Number Retrieved'),
              content: Text('Phone Number: +$phoneNumber'),
              actions: [
                TextButton(
                  onPressed: () => moveToPage(context, const HomePage(), true),
                  child: const Text('Back'),
                ),
                TextButton(
                  onPressed: () => moveToPage(context, const NumberHistoryPage(), true),
                  child: const Text('View Order'),
                ),
              ],
            ),
          );
        }
      }
    } else {
      // Handle all response scenarios
      switch (responseBody) {
        case 'MAX_PRICE_EXCEEDED':
          _response = 'Max price exceeded. Please adjust your price limit.';
          break;
        case 'NO_NUMBERS':
          _response = 'No numbers available at the moment. Try again later.';
          break;
        case 'TOO_MANY_ACTIVE_RENTALS':
          _response = 'Too many active rentals. Complete them before renting more.';
          break;
        case 'NO_MONEY':
          _response = 'Insufficient balance. Please top up your account.';
          break;
        default:
          _response = 'Unexpected response: $responseBody';
      }
      await refundBalance(_selectedService);
      throw Exception(_response);
    }
  } catch (e) {
    setState(() {
      _response = e.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_response),
      backgroundColor: Colors.red,
    ));
    print('Error: $e');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  Future<bool> refundBalance(String service) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User is not logged in.");
        return false;
      }

      // Fetch the user's current balance
      final userDocRef =
          FirebaseFirestore.instance.collection('ggsms_users').doc(user.email);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        print("User document not found.");
        return false;
      }

      // Get the user's current balance
      final int currentBalance = userDoc.data()?['balance'] ?? 0;

      // Fetch the price based on country and service, default to 1900 if not found
      final int price = priceData["United States"]?[service] ??
          priceData["United States"]?['default'] ??
          1900;

      // Calculate the new balance
      final int newBalance = currentBalance + price;

      // Update the balance in Firestore
      await userDocRef.update({'balance': newBalance});

      print("Balance refunded successfully. New balance: $newBalance");
      return true;
    } catch (e) {
      print("Error refunding balance: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('US Numbers Page'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                _filterServices(value);
                if (value == "") {
                  setState(() {
                    displayedPrice = "";
                  });
                }
              },
              controller: _searchController,
              onTap: () {
                setState(() {
                  shouldShowServiceDropdown = true;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Search Service',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (shouldShowServiceDropdown)
            SizedBox(
              height: 200,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _filteredServices.length,
                  itemBuilder: (context, index) {
                    final service = _filteredServices[index];
                    return ListTile(
                      title: Text(service.name),
                      onTap: () =>
                          _onServiceChanged(service.name, service.code),
                    );
                  },
                ),
              ),
            ),
          Text(
            'Price: ₦$displayedPrice',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 16),
          Visibility(
            visible: selectedService != "",
            child: isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : ElevatedButton(
                    onPressed: _buyService,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child:
                        const Text('Proceed', style: TextStyle(fontSize: 16)),
                  ),
          ),
        ],
      ),
    );
  }
}
