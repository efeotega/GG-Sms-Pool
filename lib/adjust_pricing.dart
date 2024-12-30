import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PricingAdjustmentPage extends StatefulWidget {
  const PricingAdjustmentPage({super.key});

  @override
  _PricingAdjustmentPageState createState() => _PricingAdjustmentPageState();
}

class _PricingAdjustmentPageState extends State<PricingAdjustmentPage> {
  List<dynamic> countries = [];
  List<dynamic> services = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  Map<String, Map<String, int>> priceData = {};
  List<Map<String, dynamic>> displayedData = [];

  @override
  void initState() {
    super.initState();
    loadPricingData();
  }

  Future<Map<String, Map<String, int>>> fetchPriceData() async {
  final priceData = <String, Map<String, int>>{};

  try {
    final priceCollection =
        await FirebaseFirestore.instance.collection('prices').get();

    for (var doc in priceCollection.docs) {
      final countryName = doc['name'] as String?;
      final servicePrices = doc['prices'] as Map<String, dynamic>?;

      if (countryName != null && servicePrices != null) {
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
      // Direct price mapping
      parsedMap[key] = value;
    } else if (value is Map<String, dynamic>) {
      // Handle nested providers (e.g., Daisy, SMSPool)
      value.forEach((providerKey, providerValue) {
        if (providerValue is int) {
          parsedMap['$key - $providerKey'] = providerValue;
        } else if (providerValue is Map<String, dynamic>) {
          providerValue.forEach((serviceKey, serviceValue) {
            if (serviceValue is int) {
              parsedMap['$key - $providerKey - $serviceKey'] = serviceValue;
            }
          });
        }
      });
    } else {
      print("Skipping invalid value for key $key: $value");
    }
  });

  return parsedMap;
}

Future<void> loadPricingData() async {
  setState(() {
    isLoading = true;
  });
  priceData = await fetchPriceData();
  setState(() {
    isLoading = false;
    displayedData = _generateDisplayedData();
  });
}

List<Map<String, dynamic>> _generateDisplayedData() {
  final List<Map<String, dynamic>> data = [];
  priceData.forEach((country, services) {
    // Sort services alphabetically
    final sortedServices = Map.fromEntries(
      services.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );

    sortedServices.forEach((service, price) {
      data.add({'country': country, 'service': service, 'price': price});
    });
  });

  // Sort by country
  data.sort((a, b) => a['country'].compareTo(b['country']));
  return data;
}

void _filterData(String query) {
  setState(() {
    displayedData = _generateDisplayedData()
        .where((item) =>
            item['country']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            item['service']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList();
  });
}

  void _showEditDialog(Map<String, dynamic> item) {
    if (item['country'] == 'United States') {
      // Show options for Daisy or SMSPool
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
                'Select Option for ${item['service']} in ${item['country']}'),
            content: const Text('Choose a pricing option: Daisy or SMSPool'),
            actions: [
              TextButton(
                onPressed: () => _showPriceInputDialog(item, 'Daisy'),
                child: const Text('Daisy'),
              ),
              TextButton(
                onPressed: () => _showPriceInputDialog(item, 'SMSPool'),
                child: const Text('SMSPool'),
              ),
            ],
          );
        },
      );
    } else {
      // Directly allow price editing for other countries
      _showDirectPriceInputDialog(item);
    }
  }

  void _showPriceInputDialog(Map<String, dynamic> item, String provider) {
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              'Set Price for $provider (${item['service']}) in ${item['country']}'),
          content: TextField(
            controller: priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateProviderPrice(
                  item['country'],
                  item['service'],
                  provider,
                  int.parse(priceController.text),
                );
                Navigator.pop(context); // Close the input dialog
                Navigator.pop(context); // Close the provider selection dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProviderPrice(
    String countryName,
    String serviceName,
    String provider,
    int price,
  ) async {
    try {
      setState(() {
        isLoading = true;
      });
      final countryRef =
          FirebaseFirestore.instance.collection('prices').doc(countryName);

      final docSnapshot = await countryRef.get();

      if (docSnapshot.exists) {
        await countryRef.update({
          'prices.$provider.$serviceName': price,
        });
      } else {
        await countryRef.set({
          'name': countryName,
          'prices': {
            provider: {
              serviceName: price,
            },
          },
        });
      }

      setState(() {
        if (!priceData.containsKey(countryName)) {
          priceData[countryName] = {};
        }
        if (!priceData[countryName]!.containsKey(provider)) {
          priceData[countryName]![provider] = 0;
        }
        priceData[countryName]![serviceName] = price;
        displayedData = _generateDisplayedData();
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price updated successfully')));
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error updating price: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error updating price')));
    }
  }

  void _showDirectPriceInputDialog(Map<String, dynamic> item) {
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Price for ${item['service']} in ${item['country']}'),
          content: TextField(
            controller: priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updatePrice(
                  item['country'],
                  item['service'],
                  int.parse(priceController.text),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePrice(
      String countryName, String serviceName, int price) async {
    try {
      setState(() {
        isLoading = true;
      });
      final countryRef =
          FirebaseFirestore.instance.collection('prices').doc(countryName);

      final docSnapshot = await countryRef.get();

      if (docSnapshot.exists) {
        await countryRef.update({
          'prices.$serviceName': price,
        });
      } else {
        await countryRef.set({
          'name': countryName,
          'prices': {
            serviceName: price,
          },
        });
      }

      setState(() {
        priceData[countryName]?[serviceName] = price;
        displayedData = _generateDisplayedData();
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price updated successfully')));
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error updating price: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error updating price')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing Adjustment')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: _filterData,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Country')),
                          DataColumn(label: Text('Service')),
                          DataColumn(label: Text('Price')),
                        ],
                        rows: displayedData
                            .map((item) => DataRow(cells: [
                                  DataCell(Text(
                                    item['country'],
                                    style: const TextStyle(fontSize: 15),
                                    ),
                                      onTap: () => _showEditDialog(item)),
                                  DataCell(Text(
                                     style: const TextStyle(fontSize: 15),
                                    item['service']),
                                      onTap: () => _showEditDialog(item)),
                                  DataCell(Text(
                                    style: const TextStyle(fontSize: 15),
                                    item['price'].toString()),
                                      onTap: () => _showEditDialog(item)),
                                ]))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
