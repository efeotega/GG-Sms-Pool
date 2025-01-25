import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'daisy_services.dart';

class PricingAdjustmentPageDaisySms extends StatefulWidget {
  const PricingAdjustmentPageDaisySms({super.key});

  @override
  _PricingAdjustmentPageDaisySmsState createState() => _PricingAdjustmentPageDaisySmsState();
}

class _PricingAdjustmentPageDaisySmsState extends State<PricingAdjustmentPageDaisySms> {
  // List of services (same as your provided services list)
 final List<Service> services = [
  Service(name: '3Fun', code: 'auw'),
  Service(name: 'AARP Rewards', code: 'aarp'),
  Service(name: 'Amazon / AWS', code: 'am'),
  Service(name: 'AOL', code: 'pm'),
  Service(name: 'Apple', code: 'wx'),
  Service(name: 'Badoo', code: 'qv'),
  Service(name: 'Bank of America', code: 'boa'),
  Service(name: 'Benjamin', code: 'bdx'),
  Service(name: 'Bet365', code: 'ie'),
  Service(name: 'Blastbucks', code: 'blastbucks'),
  Service(name: 'Blizzard / Battle.net', code: 'bz'),
  Service(name: 'BLK', code: 'blk'),
  Service(name: 'Bumble', code: 'mo'),
  Service(name: 'Capital One', code: 'apr'),
  Service(name: 'Cash App', code: 'it'),
  Service(name: 'CenturyLink', code: 'centurylink'),
  Service(name: 'Chase', code: 'chase'),
  Service(name: 'Chevron / TexaCo', code: 'afk'),
  Service(name: 'Chick-fil-A', code: 'chickfila'),
  Service(name: 'Chime', code: 'chime'),
  Service(name: 'Chipotle', code: 'chipotle'),
  Service(name: 'Chispa', code: 'ir'),
  Service(name: 'Chromakopia', code: 'yvci'),
  Service(name: 'Circle K', code: 'circlek'),
  Service(name: 'Citi', code: 'citi'),
  Service(name: 'Claude AI', code: 'acz'),
  Service(name: 'Coca-Cola', code: 'abb'),
  Service(name: 'CoD', code: 'cod'),
  Service(name: 'Coinbase', code: 're'),
  Service(name: 'College Pulse', code: 'cpulse'),
  Service(name: 'Craigslist', code: 'wc'),
  Service(name: 'Credit Karma', code: 'karma'),
  Service(name: 'CrowdTap', code: 'sx'),
  Service(name: 'Current.com', code: 'current'),
  Service(name: 'Currently.com / AT&T Email', code: 'currently'),
  Service(name: 'Deliveroo', code: 'zk'),
  Service(name: 'Discord', code: 'ds'),
  Service(name: 'DoorDash', code: 'ac'),
  Service(name: 'Dunkin Donuts', code: 'dunkin'),
  Service(name: 'Dutch Bros', code: 'dutchbros'),
  Service(name: 'eBay', code: 'dh'),
  Service(name: 'Eneba', code: 'uf'),
  Service(name: 'Etsy', code: 'alq'),
  Service(name: 'Facebook', code: 'fb'),
  Service(name: 'Feeld', code: 'ws'),
  Service(name: 'Fetch Rewards', code: 'fetchrewards'),
  Service(name: 'FetLife', code: 'fet'),
  Service(name: 'Fiverr', code: 'cn'),
  Service(name: 'Flip', code: 'flip'),
  Service(name: 'Foot Locker', code: 'footlocker'),
  Service(name: 'Frisbee Rewards', code: 'frisbee'),
  Service(name: 'Gaintplay', code: 'gaint'),
  Service(name: 'GMX.com', code: 'abk'),
  Service(name: 'Go2Bank', code: 'go2bank'),
  Service(name: 'Google / Gmail / Youtube', code: 'go'),
  Service(name: 'Google Messenger', code: 'googlemessenger'),
  Service(name: 'Google Voice', code: 'gf'),
  Service(name: 'Gopuff', code: 'ajn'),
  Service(name: 'Grindr', code: 'yw'),
  Service(name: 'Hily', code: 'rt'),
  Service(name: 'Hinge', code: 'vz'),
  Service(name: 'HSBC', code: 'hsbc'),
  Service(name: 'Ibotta', code: 'ibotta'),
  Service(name: 'Instagram', code: 'ig'),
  Service(name: 'Ipsos iSay', code: 'agk'),
  Service(name: 'JD.com', code: 'za'),
  Service(name: 'Juno', code: 'juno'),
  Service(name: 'KakaoTalk', code: 'kt'),
  Service(name: 'Keybank', code: 'keybank'),
  Service(name: 'Kraken', code: 'kraken'),
  Service(name: 'Kudos', code: 'kudos'),
  Service(name: 'LAA', code: 'laa'),
  Service(name: 'League of Legends', code: 'riot'),
  Service(name: 'LINE messenger', code: 'me'),
  Service(name: 'LinkedIn', code: 'tn'),
  Service(name: 'Linode', code: 'ex'),
  Service(name: 'Luvs', code: 'luvs'),
  Service(name: 'Lyft', code: 'tu'),
  Service(name: 'Marylous Coffee', code: 'marylous'),
  Service(name: 'Match.com', code: 'abf'),
  Service(name: 'Mercari', code: 'dg'),
  Service(name: 'Microsoft / Outlook / Hotmail', code: 'mm'),
  Service(name: 'MoneyLion', code: 'qo'),
  Service(name: 'MyGiftCardRedemption', code: 'mygiftcardredemption'),
  Service(name: 'Neocrypto', code: 'aft'),
  Service(name: 'Nike', code: 'ew'),
  Service(name: 'Noonlight', code: 'noonlight'),
  Service(name: 'OfferUp', code: 'zm'),
  Service(name: 'OkCupid', code: 'vm'),
  Service(name: 'One.app', code: 'oneapp'),
  Service(name: 'OpenAI / ChatGPT', code: 'dr'),
  Service(name: 'OpenTable', code: 'opentable'),
  Service(name: 'PayPal', code: 'ts'),
  Service(name: 'Pelago', code: 'pelago'),
  Service(name: 'Phoner', code: 'phoner'),
  Service(name: 'Phound', code: 'fp'),
  Service(name: 'Pinger', code: 'pinger'),
  Service(name: 'Pixels.xyz', code: 'pixels'),
  Service(name: 'Plaid', code: 'plaid'),
  Service(name: 'Plenty of Fish', code: 'pf'),
  Service(name: 'PNC', code: 'pnc'),
  Service(name: 'Pogo', code: 'pogo'),
  Service(name: 'Poshmark', code: 'oz'),
  Service(name: 'PVC', code: 'pvc'),
  Service(name: 'Rate4Rewards', code: 'r4r'),
  Service(name: 'Rebtel', code: 'ajj'),
  Service(name: 'Regions', code: 'regions'),
  Service(name: 'Resy.com', code: 'resy'),
  Service(name: 'RevTrax', code: 'revtrax'),
  Service(name: 'Ring4', code: 'ring4'),
  Service(name: 'Santander', code: 'lj'),
  Service(name: 'Schwab', code: 'schwab'),
  Service(name: 'Seated', code: 'are'),
  Service(name: 'Service not listed', code: 'unlisted'),
  Service(name: 'SHEIN', code: 'aez'),
  Service(name: 'ShiftKey', code: 'shiftkey'),
  Service(name: 'Shop.app', code: 'shop'),
  Service(name: 'Sideline / Index by Pinger', code: 'sideline'),
  Service(name: 'Signal', code: 'bw'),
  Service(name: 'Skrill', code: 'aqt'),
  Service(name: 'Snapchat', code: 'fu'),
  Service(name: 'Snaplii', code: 'snaplii'),
  Service(name: 'Square', code: 'bbg'),
  Service(name: 'Steam', code: 'mt'),
  Service(name: 'Swagbucks / InboxDollars / MyPoints / ySense / Noones / Adgate Survey', code: 'swag'),
  Service(name: 'Taimi', code: 'taimi'),
  Service(name: 'Telegram', code: 'tg'),
  Service(name: 'Temu', code: 'ep'),
  Service(name: 'TextFree', code: 'asf'),
  Service(name: 'Textr', code: 'textr'),
  Service(name: 'Ticketmaster', code: 'gp'),
  Service(name: 'TikTok', code: 'lf'),
  Service(name: 'Timewall', code: 'timewall'),
  Service(name: 'Tinder', code: 'oi'),
  Service(name: 'TrapCall', code: 'trapcall'),
  Service(name: 'Truist', code: 'truist'),
  Service(name: 'Truth Social', code: 'ada'),
  Service(name: 'Twitch', code: 'hb'),
  Service(name: 'Twitter', code: 'tw'),
  Service(name: 'Uber', code: 'ub'),
  Service(name: 'USAA', code: 'usaa'),
  Service(name: 'Venmo', code: 'yy'),
  Service(name: 'Verasight', code: 'verasight'),
  Service(name: 'Viber', code: 'vi'),
  Service(name: 'Vision Engage', code: 'vision_engage'),
  Service(name: 'VKontakte', code: 'vk'),
  Service(name: 'Walmart', code: 'wr'),
  Service(name: 'Webull', code: 'alf'),
  Service(name: 'WeChat', code: 'wb'),
  Service(name: 'Wells Fargo', code: 'wfargo'),
  Service(name: 'Wert', code: 'wert'),
  Service(name: 'Western Union', code: 'wu'),
  Service(name: 'WhatsApp', code: 'wa'),
  Service(name: 'Wise', code: 'bo'),
  Service(name: 'Wolt', code: 'rr'),
  Service(name: 'Yahoo', code: 'mb'),
  Service(name: 'Zalo', code: 'mj'),
  Service(name: 'Zyrtec', code: 'zyrtec'),
];


  // Controller to handle the search input
  final TextEditingController _searchController = TextEditingController();

  // List of services to display based on search query
  List<Service> _filteredServices = [];

  @override
  void initState() {
    super.initState();
    // Initially, show all services
    _filteredServices = services;

    // Listen to search text changes
    _searchController.addListener(_filterServices);
  }

  // Filter services based on the input
  void _filterServices() {
    setState(() {
      _filteredServices = services
          .where((service) => service.name.toLowerCase().contains(
              _searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search for a Service'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search for a service...',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredServices.length,
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                return ListTile(
                  title: Text(service.name),
                  onTap: () {
                    // You can navigate to a new page to set the price
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetPricePage(service: service),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SetPricePage extends StatelessWidget {
  final Service service;
  const SetPricePage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    TextEditingController priceController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Set Price for ${service.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Enter the price for ${service.name}:'),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final price = int.tryParse(priceController.text);
                if (price != null) {
                  // Save the price to Firebase Firestore
                  savePriceToFirestore(context,service, price);
                }
              },
              child: const Text('Save Price'),
            ),
          ],
        ),
      ),
    );
  }

  // Save the price to Firestore
  Future<void> savePriceToFirestore(BuildContext context,Service service, int price) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('ggsms_prices_daisysms').doc('United States').set({
      'name':"United States",
      'prices': {
        service.name: price,
      },
    }, SetOptions(merge: true));
    Navigator.of(context).pop();
ScaffoldMessenger.of(context)
          .showSnackBar( SnackBar(content: Text('Price saved for ${service.name}: $price')));
   
    
  }
}

