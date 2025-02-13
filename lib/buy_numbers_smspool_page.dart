import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gg_sms_pool/home_page.dart';
import 'package:gg_sms_pool/number_history_page.dart';
import 'package:gg_sms_pool/utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BuyNumbersPageSmsPool extends StatefulWidget {
  const BuyNumbersPageSmsPool({super.key});

  @override
  _BuyNumbersPageSmsPoolState createState() => _BuyNumbersPageSmsPoolState();
}

class _BuyNumbersPageSmsPoolState extends State<BuyNumbersPageSmsPool> {
  bool isLoading = false;
  Map<String, Map<String, int>> priceData = {};
  String searchQuery="";
  bool isCountryDropdownVisible=false;
  bool isServiceDropdownVisible=false;
  TextEditingController countryController=TextEditingController();
  TextEditingController serviceController=TextEditingController();
  List<dynamic> countries = [];
  List<dynamic> services = [];
  List<dynamic> filteredCountries = [];
  List<dynamic> filteredServices = [];
  String? selectedCountry;
  int? selectedCountryId;
  String? selectedService;
  bool isLoadingServices =
      false; // Added flag to show loading state for services
  String displayedPrice="0";
  String countrySearch = '';
  String serviceSearch = '';


  void showNumberGottenDialog(BuildContext context, String number) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Successful'),
          content: Text('Your number is +$number'),
          actions: [
            TextButton(
              onPressed: () {
               moveToPage(context, const HomePage(), true);// Close the dialog
              },
              child: const Text('View Order'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Back'),
            ),
          ],
        );
      },
    );
  }
  
  void showNumberOutOfStockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Apologies'),
          content: Text('Numbers for $selectedService in $selectedCountry is currently out of stock, please try another country or service'),
          actions: [
           
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  void loadPricingData() async {
  
  var priceDatal = await fetchPriceData();
  setState(() {
    priceData = priceDatal; // Use this in your app logic
  });
}

Future<Map<String, Map<String, int>>> fetchPriceData() async {
  final priceData = <String, Map<String, int>>{};

  try {
    // Fetch all documents in the "prices" collection
    final priceCollection =
        await FirebaseFirestore.instance.collection('ggsms_prices_smspool').get();

    // Iterate through each document
    for (var doc in priceCollection.docs) {
      final countryName = doc['name'] as String?;
      final servicePrices = doc['prices'] as Map<String, dynamic>?;

      if (countryName != null && servicePrices != null) {
        // Convert dynamic map to a Map<String, int>, handling nested maps
        final priceMap = _parsePriceMap(servicePrices);
        priceData[countryName] = priceMap;
      }
    }
  } catch (e) {
    print("Error fetching price data: $e");
  }

  return priceData;
}

// Helper function to parse prices map recursively
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
    _fetchCountries();
    serviceController.addListener(() {
      _filterServices(serviceController.text);
    });
    loadPricingData();
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

      // Fetch the price based on country and service, default to 1900 if not found
      final int price = priceData[country]?[service] ??
          priceData[country]?['default'] ??
          1900;

      // Check if user has enough balance
      if (currentBalance < price) {
        setState(() {
          isLoading=false;
        });
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

  Future<bool> refundBalance(String country, String service) async {
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
      final int price = priceData[country]?[service] ??
          priceData[country]?['default'] ??
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

  Future<void> _fetchCountries() async {
    final url = Uri.parse('https://api.smspool.net/country/retrieve_all');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        countries = data;
        filteredCountries = countries;
      });
    } else {
      // Handle error
    }
  }

  Future<void> _fetchServices(String countryId) async {
    setState(() {
      isLoadingServices = true; // Set loading state to true
      services = [];
      selectedService = null;
      displayedPrice = "0";
      serviceSearch = ''; // Reset service search
    });

    final url = Uri.parse(
        'https://api.smspool.net/service/retrieve_all?country=$countryId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        services = data;
        filteredServices = services;
        isLoadingServices = false; // Set loading state to false
      });
    } else {
      // Handle error
      setState(() {
        isLoadingServices = false; // Ensure loading state is reset on error
      });
    }
  }

  void _onCountryChanged(String? value) {
    if (value != null) {
      setState(() {
        selectedCountry = value;
        countryController.text=value;
        isCountryDropdownVisible=false;
        selectedCountryId = filteredCountries
            .firstWhere((country) => country['name'] == value)['ID'];
        print("country id: $selectedCountryId");
        displayedPrice = "0"; // Reset price when country is changed
      });
      _fetchServices(value);
    }
  }

  void _onServiceChanged(String? value) {
    setState(() {
      selectedService = value;
      isServiceDropdownVisible=false;
      serviceController.text=value!;
    });

    if (selectedCountry != null && selectedService != null) {
     
    
      // Set the displayed price based on the selected country and service
      setState(() {
        final countryPrices = priceData[selectedCountry] ?? {};
     displayedPrice =(countryPrices[selectedService] ?? countryPrices['default'] ?? 1900).toString();

        // displayedPrice =
        //     '₦${priceData[selectedCountry]?[value] ?? priceData[selectedService]!['default']}';
      });
    }
    else{
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error')));
    
    }
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
        'server':"smspool",
        'orderId': orderId,
        "status":1,
        'price':displayedPrice,
        'date': FieldValue.serverTimestamp(),
      });

      print("Number saved successfully in Firestore.");
    } catch (e) {
      print("Failed to save number: $e");
    }
  }

  void _onProceed() async {
  if (isLoading) return;

  setState(() {
    isLoading = true;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please wait..."),
      backgroundColor: Colors.blue,
    ),
  );

  if (selectedCountry == null || selectedService == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select both country and service'),
        backgroundColor: Colors.red,
      ),
    );
    setState(() {
      isLoading = false;
    });
    return;
  }

  if (await deductBalance(selectedCountry!, selectedService!)) {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.smspool.net/purchase/sms'),
      );

      request.fields.addAll({
        'key': 'yFXHjau7PV6Dox8sA2YD8wD9Ak4kP5pC',
        'country': selectedCountryId!.toString(),
        'service': selectedService!,
        'pool': '',
        'max_price': '1.90',
        'pricing_option': '0',
        'quantity': '1',
        'areacode': '',
        'exclude': '',
        'create_token': ''
      });

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);

        if (jsonResponse.containsKey('number')) {
          String purchasedNumber = jsonResponse['number'].toString();
          String orderId = jsonResponse['order_id'];
          showNumberGottenDialog(context, purchasedNumber);
          await savePurchasedNumber(purchasedNumber, selectedService!, orderId);
        } else {
          await refundBalance(selectedCountry!, selectedService!);
          final errorMessage = responseBody.contains("This service is currently not available")
              ? 'This service is currently not available.'
              : 'Failed to retrieve the purchased number.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } else {
        if (response.statusCode == 422) {
          showNumberOutOfStockDialog(context);
        } else {
          String responseBody = await response.stream.bytesToString();
          final jsonResponse = jsonDecode(responseBody);
          if (jsonResponse.containsKey('message')) {
            print("Error message: ${jsonResponse['message']}");
          }
        }
        await refundBalance(selectedCountry!, selectedService!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to purchase number.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  } else {
    setState(() {
      isLoading = false;
    });
  }
}

  // Filter countries based on search query
  void _filterCountries(String query) {
    final filtered = countries.where((country) {
      final name = country['name'].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
    setState(() {
      countrySearch = query;
      filteredCountries = filtered;
      // Reset the selected country if it's no longer in the filtered list
      if (selectedCountry != null &&
          !filteredCountries
              .any((country) => country['name'] == selectedCountry)) {
        selectedCountry = null;
      }
      isCountryDropdownVisible = filteredCountries.isNotEmpty;
    });
  }

  // Filter services based on search query
  void _filterServices(String query) {
    final filtered = services.where((service) {
      final name = service['name'].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
    setState(() {
      searchQuery=query;
      serviceSearch = query;
      filteredServices = filtered;
      // Reset the selected service if it's no longer in the filtered list
      if (selectedService != null &&
          !filteredServices
              .any((service) => service['name'] == selectedService)) {
        selectedService = null;
      }
      isServiceDropdownVisible=filteredServices.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buy Numbers',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a country and a service to proceed',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            // Country Search Bar
            TextField(
            controller: countryController,
            onChanged: _filterCountries,
            onTap: () {
              // Show dropdown when tapping on the search field
              setState(() {
                isCountryDropdownVisible = true;
              });
            },
            decoration: InputDecoration(
              labelText: 'Search for Country',
              labelStyle: const TextStyle(color: Colors.blueAccent),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          if (isCountryDropdownVisible)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredCountries.length,
                itemBuilder: (context, index) {
                  final country = filteredCountries[index]['name']!;
                  return ListTile(
                    title: Text(country),
                    onTap: () => _onCountryChanged(country),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Service Search Bar
            if (selectedCountry != null) ...[
          // Service Search Bar
          TextField(
          controller: serviceController,
          onTap: () {
            setState(() {
              isServiceDropdownVisible = true;
            });
          },
          decoration: InputDecoration(
            labelText: 'Search for Service',
            labelStyle: const TextStyle(color: Colors.blueAccent),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        // Service Dropdown List
        if (isServiceDropdownVisible)
          SizedBox(
            height: 200,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: filteredServices.length,
                itemBuilder: (context, index) {
                  final service = filteredServices[index]['name']!;
                  return ListTile(
                    title: Text(service),
                    onTap: () => _onServiceChanged(service),
                  );
                },
              ),
            ),
          ),
       
            ],
            const SizedBox(height: 16),
            // Display price
            // if (displayedPrice != null)
              Text(
                'Price: ₦$displayedPrice',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            const SizedBox(height: 16),
            // Proceed Button
            isLoading?const CircularProgressIndicator(
                      color: Colors.white,
                    ):
            ElevatedButton(
              onPressed: _onProceed,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text('Proceed', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}