import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gg_sms_pool/number_history_page.dart';
import 'package:gg_sms_pool/utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BuyNumbersPageSmsBus extends StatefulWidget {
  const BuyNumbersPageSmsBus({super.key});

  @override
  _BuyNumbersPageSmsBusState createState() => _BuyNumbersPageSmsBusState();
}

class _BuyNumbersPageSmsBusState extends State<BuyNumbersPageSmsBus> {
  bool isLoading = false;
  Map<String, Map<String, int>> priceData = {};
  String searchQuery = "";
  bool isCountryDropdownVisible = false;
  bool isServiceDropdownVisible = false;
  TextEditingController countryController = TextEditingController();
  TextEditingController serviceController = TextEditingController();
  List<dynamic> countries = [];
  List<dynamic> services = [];
  List<dynamic> filteredCountries = [];
  List<dynamic> filteredServices = [];
  String? selectedCountry;
  int selectedCountryId=0;
  String? selectedService;
  int selectedServiceId=0;
  bool isLoadingServices =
      false; // Added flag to show loading state for services
  String displayedPrice = "0";
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
                moveToPage(context, const NumberHistoryPage(),
                    false); // Close the dialog
              },
              child: const Text('View SMS Code'),
            ),
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

  void showNumberOutOfStockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Apologies'),
          content: Text(
              'Numbers for $selectedService in $selectedCountry is currently out of stock, please try another country or service'),
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
      final priceCollection = await FirebaseFirestore.instance
          .collection('ggsms_prices_smsbus')
          .get();

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

  // // Price data based on country and service
  // final Map<String, Map<String, int>> priceData = {
  //   'United States': {
  //     'WhatsApp': 2500,
  //     'Telegram': 3500,
  //     'Signal': 1800,
  //     'OkCupid': 2000,
  //     'Google/Gmail': 2000,
  //     'Apple': 1500,
  //     'default': 1500,
  //   },
  //   'United Kingdom': {
  //     'WhatsApp': 3000,
  //     'Telegram': 3000,
  //     'Signal': 1500,
  //     'Google/Gmail': 2300,
  //     'Apple': 2000,
  //     'OkCupid': 1900,
  //     'default': 2000,
  //   },
  // };

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

      // Fetch the price based on country and service, default to 1500 if not found
      final int price = priceData[country]?[service] ??
          priceData[country]?['default'] ??
          1500;

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

      // Fetch the price based on country and service, default to 1500 if not found
      final int price = priceData[country]?[service] ??
          priceData[country]?['default'] ??
          1500;

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
    String token = "c5027c1a4b3c4dbe96442be795c8d5b3";
    final url = Uri.parse(
        'https://sms-bus.com/api/control/list/countries?token=$token');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Debugging: Print the entire response to understand the structure
      final Map<String, dynamic> data = json.decode(response.body);
      print("Response data: $data");

      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        print("Found countries");
        setState(() {
          // Extract map values and convert to a list
          countries = data['data'].values.toList();
          filteredCountries = countries;
        });
      } else {
        print("Unexpected data format: 'data' key not found or invalid type");
      }
    } else {
      // Handle error
      print("Failed to fetch countries: ${response.statusCode}");
    }
  }

  Future<void> _fetchServices(String countryId) async {
    String token = "c5027c1a4b3c4dbe96442be795c8d5b3";
    setState(() {
      isLoadingServices = true; // Set loading state to true
      services = [];
      selectedService = null;
      displayedPrice = "0";
      serviceSearch = ''; // Reset service search
    });

    final url =
        Uri.parse('https://sms-bus.com/api/control/list/projects?token=$token');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        final servicesData = data['data'] as Map<String, dynamic>;

        // Convert the services data map into a list of services
        final List<Map<String, dynamic>> serviceList = servicesData.values
            .map((service) => service as Map<String, dynamic>)
            .toList();

        setState(() {
          services = serviceList;
          filteredServices = services;
          isLoadingServices = false; // Set loading state to false
        });
      } else {
        print("Unexpected data format: 'data' key not found or invalid type");
        setState(() {
          isLoadingServices = false; // Ensure loading state is reset on error
        });
      }
    } else {
      // Handle error
      print("Failed to fetch services: ${response.statusCode}");
      setState(() {
        isLoadingServices = false; // Ensure loading state is reset on error
      });
    }
  }

  void _onCountryChanged(String? value,int id) {
    if (value != null) {
      setState(() {
        selectedCountry = value;
        selectedCountryId = id;
        countryController.text = value;
        isCountryDropdownVisible = false;
        selectedCountryId = filteredCountries
            .firstWhere((country) => country['title'] == value)['id'];
        print("country id: $selectedCountryId");
        displayedPrice = "0"; // Reset price when country is changed
      });
      _fetchServices(value);
    }
  }

  void _onServiceChanged(String? value,int id) {
    setState(() {
      selectedService = value;
      selectedServiceId=id;
      isServiceDropdownVisible = false;
      serviceController.text = value!;
    });

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
        'orderId': orderId,
        'server': "smsbus",
        'price': displayedPrice,
        "status":1,
        'date': FieldValue.serverTimestamp(),
      });

      print("Number saved successfully in Firestore.");
    } catch (e) {
      print("Failed to save number: $e");
    }
  }

  void _onProceed() async {
    if(isLoading){
      return;
    }
    setState(() {
      isLoading = true;
    });

    if (selectedCountry != null && selectedService != null) {
      // Deduct displayedPrice variable from user balance if necessary before making the request
      if (await deductBalance(selectedCountry!, selectedService!)) {
        // Prepare the URL for the GET request
        const token =
            "c5027c1a4b3c4dbe96442be795c8d5b3"; // Replace with your token
        final countryId =
            selectedCountryId; // Assuming you have country ID
        final projectId =
            selectedServiceId; // Assuming selectedService holds the project ID

        final url = Uri.parse(
            'https://sms-bus.com/api/control/get/number?token=$token&country_id=$countryId&project_id=$projectId');

        final response = await http.get(url);

        if (response.statusCode == 200) {
          setState(() {
            isLoading = false;
          });

          // Convert the response body to a string
          String responseBody = response.body;
          print("Response: $responseBody");

          // Parse the response body as JSON
          final jsonResponse = jsonDecode(responseBody);

          // Check if the "data" and "number" fields exist
          if (jsonResponse['code'] == 200 &&
              jsonResponse['data'] != null &&
              jsonResponse['data']['number'] != null) {
            String purchasedNumber = jsonResponse['data']['number'];
            String requestId = jsonResponse['data']['request_id']
                .toString(); // Assuming request_id is also useful
            print("Purchased number: $purchasedNumber");

            showNumberGottenDialog(context, purchasedNumber);
            await savePurchasedNumber(
                purchasedNumber, selectedService!, requestId);
          } else {
            setState(() {
              isLoading = false;
            });
            await refundBalance(selectedCountry!, selectedService!);

            // If the number field is not found or the code is not 200
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to retrieve the purchased number.'),
              backgroundColor: Colors.red,
            ));
          }
        } else {
          setState(() {
            isLoading = false;
          });

          // Handle error response
          String responseBody = response.body;
          print("Error response: $responseBody");

          final jsonResponse = jsonDecode(responseBody);
          if (jsonResponse.containsKey('message')) {
            String message = jsonResponse['message'];
            print("Error message: $message");
          }
          await refundBalance(selectedCountry!, selectedService!);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to purchase number.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select both country and service'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Filter countries based on search query
  void _filterCountries(String query) {
    final filtered = countries.where((country) {
      final name = country['title'].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    // Sort the filtered list alphabetically by country title
    filtered.sort((a, b) {
      final nameA = a['title'].toLowerCase();
      final nameB = b['title'].toLowerCase();
      return nameA.compareTo(nameB); // This sorts alphabetically
    });

    setState(() {
      countrySearch = query;
      filteredCountries = filtered;

      // Reset the selected country if it's no longer in the filtered list
      if (selectedCountry != null &&
          !filteredCountries
              .any((country) => country['title'] == selectedCountry)) {
        selectedCountry = null;
      }
      isCountryDropdownVisible = filteredCountries.isNotEmpty;
    });
  }

  // Filter services based on search query
  void _filterServices(String query) {
    final filtered = services.where((service) {
      final name = service['title'].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
    setState(() {
      searchQuery = query;
      serviceSearch = query;
      filteredServices = filtered;
      // Reset the selected service if it's no longer in the filtered list
      if (selectedService != null &&
          !filteredServices
              .any((service) => service['title'] == selectedService)) {
        selectedService = null;
      }
      isServiceDropdownVisible = filteredServices.isNotEmpty;
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
                    //sort the filteredCountries list alphabetically
                    filteredCountries.sort((a, b) {
                      final nameA = a['title'].toLowerCase();
                      final nameB = b['title'].toLowerCase();
                      return nameA
                          .compareTo(nameB); // This sorts alphabetically
                    });
                    final country = filteredCountries[index]['title']!;
                    int id = filteredCountries[index]['id']!;
                    return ListTile(
                      title: Text(country),
                      onTap: () => _onCountryChanged(country,id),
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
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
                        //sort the filteredServices list alphabetically
                        filteredServices.sort((a, b) {
                          final nameA = a['title'].toLowerCase();
                          final nameB = b['title'].toLowerCase();
                          return nameA.compareTo(nameB);
                        }); // This sorts alphabetically
                        final service = filteredServices[index]['title']!;
                        final id = filteredServices[index]['id']!;
                        return ListTile(
                          title: Text(service),
                          onTap: () => _onServiceChanged(service,id),
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
                    ): ElevatedButton(
              onPressed: _onProceed,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.blueAccent,
              ),
              child:const Text('Proceed', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
