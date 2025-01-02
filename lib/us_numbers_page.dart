import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gg_sms_pool/daisy_services.dart';
import 'package:gg_sms_pool/number_history_page.dart';
import 'package:gg_sms_pool/utils.dart';

import 'package:http/http.dart' as http;

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
          .collection('ggsms_purchased_numbers')
          .doc();

      // Save the number and date
      await userRef.set({
        'number': number,
        'service': service,
        'orderId': orderId,
        'server': "daisysms",
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

  var priceDataForNonSMSPool = await fetchPriceDataExcludeSMSPool();

  setState(() {
    priceData = priceDataForNonSMSPool;
    isLoading = false;
  });
}


Future<Map<String, Map<String, int>>> fetchPriceDataExcludeSMSPool() async {
  final priceData = <String, Map<String, int>>{};

  try {
    // Fetch all documents in the "prices" collection
    final priceCollection =
        await FirebaseFirestore.instance.collection('ggsms_prices').get();

    for (var doc in priceCollection.docs) {
      final countryName = doc['name'] as String?;
      final servicePrices = doc['prices'] as Map<String, dynamic>?;

      if (countryName != null && servicePrices != null) {
        final filteredServices = <String, int>{};

        // Iterate through each service and exclude "SMSPool"
        servicePrices.forEach((service, priceMap) {
          if (service != 'SMSPool' && priceMap is Map<String, dynamic>) {
            final parsedMap = _parsePriceMap(priceMap);
            filteredServices.addAll(parsedMap);
          }
        });

        if (filteredServices.isNotEmpty) {
          priceData[countryName] = filteredServices;
        }
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
    if(await deductBalance("United States", _selectedService)){
      setState(() {
      isLoading = true;
    });
    if (_selectedCode.isEmpty) {
      print("no code");
      setState(() {
        isLoading = false;
      });
      setState(() {
        _response = 'No service selected!';
      });
      return;
    }
    print("starting");
    const String apiKey = 'X8PiPQWlxSKYSNcOOWBwYOaze6hgkZ';
    var url = 'https://api.allorigins.win/get?url=${Uri.encodeComponent(
            'https://daisysms.com/stubs/handler_api.php?api_key=$apiKey&action=getNumber&service=$_selectedCode&max_price=2.0')}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
       
        final responseBody = response.body.trim();

        if (responseBody.startsWith('ACCESS_NUMBER')) {
          final parts = responseBody.split(':');
          if (parts.length >= 3) {
            final String id = parts[1];
            final String phoneNumber = parts[2];
            await savePurchasedNumber(phoneNumber, _selectedService, id);
            // Show phone number in dialog
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Number Retrieved'),
                    content: Text('Phone Number: +$phoneNumber'),
                    actions: [
                      TextButton(
                        onPressed: () => moveToPage(
                            context, const NumberHistoryPage(), false),
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          }
        } else if (responseBody == 'MAX_PRICE_EXCEEDED') {
          setState(() {
            isLoading = false;
            _response = 'Max price exceeded. Please adjust your price limit.';
          });
        } else if (responseBody == 'NO_NUMBERS') {
          setState(() {
            isLoading = false;
            _response = 'No numbers available at the moment. Try again later.';
          });
        } else if (responseBody == 'TOO_MANY_ACTIVE_RENTALS') {
          setState(() {
            isLoading = false;
            _response =
                'Too many active rentals. Complete them before renting more.';
          });
        } else if (responseBody == 'NO_MONEY') {
          setState(() {
            isLoading = false;
            _response = 'Insufficient balance. Please top up your account.';
          });
        } else {
          
          final parts = responseBody.split(':');
          if (parts.length >= 3) {
             print(response.body);
            final String id = parts[2];
            print("id:$id");
            final String phoneNumber = parts[3].replaceAll('","status"', "");
            await savePurchasedNumber(phoneNumber, _selectedService, id);
            // Show phone number in dialog
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Number Retrieved'),
                    content: Text('Phone Number: +$phoneNumber'),
                    actions: [
                      TextButton(
                        onPressed: () => moveToPage(
                            context, const NumberHistoryPage(), false),
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          }
        }
      } else {
        setState(() {
          isLoading = false;
          _response = 'Failed to fetch SMS. Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _response = 'Failed to fetch SMS. Error: $e';
      });
      print('Error: $e');
    }
    }
    else{
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:  Text(
              "Error"),
          backgroundColor: Colors.red,
        ));
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
            child: ElevatedButton(
              onPressed: _buyService,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.blueAccent,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text('Proceed', style: TextStyle(fontSize: 16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Response: $_response',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
