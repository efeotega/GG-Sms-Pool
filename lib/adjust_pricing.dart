import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class PricingAdjustmentPage extends StatefulWidget {
  const PricingAdjustmentPage({super.key});

  @override
  _PricingAdjustmentPageState createState() => _PricingAdjustmentPageState();
}

class _PricingAdjustmentPageState extends State<PricingAdjustmentPage> {
  List<dynamic> countries = [];
  int? updatedPrice;
  List<dynamic> filteredCountries = [];
  List<dynamic> services = [];
  List<dynamic> filteredServices = [];
  TextEditingController countryController = TextEditingController();
  TextEditingController serviceController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  bool isLoadingServices = false;
  bool isCountriesVisible = false;
  bool isServicesVisible = false;
  String? selectedCountry;
  bool isLoading = false;
  String? selectedService;
  Map<String, Map<String, int>> priceData = {};
  @override
  void initState() {
    super.initState();
    _fetchCountries();
    loadPricingData();
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
    }
  }

  Future<void> _fetchServices(String countryId) async {
    setState(() {
      isLoadingServices = true;
      services = [];
      filteredServices = [];
      selectedService = null;
    });

    final url = Uri.parse(
        'https://api.smspool.net/service/retrieve_all?country=$countryId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        services = data;
        filteredServices = services;
        isLoadingServices = false;
      });
    } else {
      setState(() {
        isLoadingServices = false;
      });
    }
  }

  Future<void> loadPricingData() async {
    setState(() {
      isLoading=true;
    });
    priceData = await fetchPriceData();
    setState(() {
      isLoading=false;
    });
  }

  Future<Map<String, Map<String, int>>> fetchPriceData() async {
  final priceData = <String, Map<String, int>>{};

  try {
    // Fetch all documents in the "prices" collection
    final priceCollection =
        await FirebaseFirestore.instance.collection('prices').get();

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

  void _filterCountries(String query) {
    setState(() {
      filteredCountries = countries
          .where((country) => country['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _filterServices(String query) {
    setState(() {
      filteredServices = services
          .where((service) => service['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
    priceController.text =
        priceData[selectedCountry]![selectedService]!.toString();
  }

  Future<void> _updatePrice(
      String countryName, String serviceName, int price) async {
    try {
      setState(() {
        isLoading = true;
      });
      // Reference to the country document in Firestore
      final countryRef =
          FirebaseFirestore.instance.collection('prices').doc(countryName);

      // Check if the document exists
      final docSnapshot = await countryRef.get();

      if (docSnapshot.exists) {
        // If the document exists, update the price
        await countryRef.update({
          'prices.$serviceName': price,
        });
      } else {
        // If the document doesn't exist, create it with the price data
        await countryRef.set({
          'name': countryName, // Set country name as part of the document
          'prices': {
            serviceName: price, // Set the initial service price
          },
        });
      }

      // Update the local map
      setState(() {
        priceData[countryName]?[serviceName] = price;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Price updated successfully')));
          setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error updating price: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error updating price')));
    }
  }

  void _showPricing(String country, String service) {
    final countryPrices = priceData[country] ?? {};
    final price = countryPrices[service] ?? countryPrices['default'] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$service Price in $country'),
          content: Text('Price: $price'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Country and Service')),
      body: isLoading?const Center(child: Column(
        children: [
           CircularProgressIndicator(),
        ],
      )):Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Field for Country
            TextField(
              onTap: () {
                setState(() {
                  isCountriesVisible = true;
                });
              },
              controller: countryController,
              onChanged: _filterCountries,
              decoration: InputDecoration(
                labelText: 'Search for Country',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            const SizedBox(height: 8),

            // ListView for Filtered Countries
            if (isCountriesVisible)
              Expanded(
                child: ListView.builder(
                  itemCount: filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = filteredCountries[index];
                    return ListTile(
                      title: Text(country['name']),
                      onTap: () {
                        setState(() {
                          isCountriesVisible = false;
                          selectedCountry = country['name'];
                          countryController.text = country["name"];
                          _fetchServices(country['ID'].toString());
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Search Field for Service
            if (selectedCountry != null) ...[
              TextField(
                onTap: () {
                  isServicesVisible = true;
                },
                controller: serviceController,
                onChanged: _filterServices,
                decoration: InputDecoration(
                  labelText: 'Search for Service',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
              const SizedBox(height: 8),

              // Loading Indicator or ListView for Filtered Services
              isLoadingServices
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: isServicesVisible
                          ? ListView.builder(
                              itemCount: filteredServices.length,
                              itemBuilder: (context, index) {
                                final service = filteredServices[index];
                                return ListTile(
                                  title: Text(service['name']),
                                  onTap: () {
                                    setState(() {
                                      isServicesVisible = false;
                                      selectedService = service['name'];
                                      serviceController.text = service['name'];
                                    });
                                    _showPricing(
                                        selectedCountry!, selectedService!);
                                  },
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
              if (selectedService != null) ...[
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Enter new price for $selectedService',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  // onChanged: (value) {
                  //   setState(() {
                  //     updatedPrice = int.tryParse(value);
                  //   });
                  // },
                ),
                const SizedBox(height: 8),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          _updatePrice(selectedCountry!, selectedService!,
                              int.parse(priceController.text));
                        },
                        child: const Text('Update Price'),
                      ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
