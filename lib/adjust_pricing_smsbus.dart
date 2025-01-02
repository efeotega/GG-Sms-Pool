import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class PricingAdjustmentPageSmsBus extends StatefulWidget {
  const PricingAdjustmentPageSmsBus({super.key});

  @override
  _PricingAdjustmentPageSmsBusState createState() =>
      _PricingAdjustmentPageSmsBusState();
}

class _PricingAdjustmentPageSmsBusState
    extends State<PricingAdjustmentPageSmsBus> {
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

  Future<void> loadPricingData() async {
    setState(() {
      isLoading = true;
    });
    priceData = await fetchPriceData();
    setState(() {
      isLoading = false;
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
      filteredCountries = filtered;

      // Reset the selected country if it's no longer in the filtered list
      if (selectedCountry != null &&
          !filteredCountries
              .any((country) => country['title'] == selectedCountry)) {
        selectedCountry = null;
      }
    });
  }

  // Filter services based on search query
  void _filterServices(String query) {
    final filtered = services.where((service) {
      final name = service['title'].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
    setState(() {
      filteredServices = filtered;
      // Reset the selected service if it's no longer in the filtered list
      if (selectedService != null &&
          !filteredServices
              .any((service) => service['title'] == selectedService)) {
        selectedService = null;
      }
    });
  }

  Future<void> _updatePrice(
      String countryName, String serviceName, int price) async {
    try {
      setState(() {
        isLoading = true;
      });
      // Reference to the country document in Firestore
      final countryRef = FirebaseFirestore.instance
          .collection('ggsms_prices_smsbus')
          .doc(countryName);

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

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price updated successfully')));
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
      appBar: AppBar(title: const Text('Adjust Price For SmsBus')),
      body: isLoading
          ? const Center(
              child: Column(
              children: [
                CircularProgressIndicator(),
              ],
            ))
          : Padding(
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ListView for Filtered Countries
                  if (isCountriesVisible)
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          filteredCountries.sort((a, b) {
                            final nameA = a['title'].toLowerCase();
                            final nameB = b['title'].toLowerCase();
                            return nameA
                                .compareTo(nameB); // This sorts alphabetically
                          });
                          final country = filteredCountries[index];
                          return ListTile(
                            title: Text(country['title']),
                            onTap: () {
                              setState(() {
                                isCountriesVisible = false;
                                selectedCountry = country['title'];
                                countryController.text = country["title"];
                                _fetchServices(country['id'].toString());
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
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
                                      //sort the filteredServices list alphabetically
                                      filteredServices.sort((a, b) {
                                        final nameA = a['title'].toLowerCase();
                                        final nameB = b['title'].toLowerCase();
                                        return nameA.compareTo(nameB);
                                      });
                                      final service = filteredServices[index];
                                      return ListTile(
                                        title: Text(service['title']),
                                        onTap: () {
                                          setState(() {
                                            isServicesVisible = false;
                                            selectedService = service['title'];
                                            serviceController.text =
                                                service['title'];
                                          });
                                          _showPricing(selectedCountry!,
                                              selectedService!);
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
