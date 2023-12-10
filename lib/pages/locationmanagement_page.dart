import 'package:csc_picker/csc_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationManagementPage extends StatefulWidget {
  @override
  _LocationManagementPageState createState() => _LocationManagementPageState();
}

class _LocationManagementPageState extends State<LocationManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController venueController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  String? countryValue = '';
  String? stateValue = '';
  String? cityValue = '';

  String _extractCountryName(String fullCountry) {
    // Remove the flag emoji from the country name
    return fullCountry.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim();
  }

  void _openCreateLocationMenu(BuildContext context) {
    TextEditingController venueController = TextEditingController();
    TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Location'),
          content: Padding(
            padding: const EdgeInsets.all(8.0), // Added padding here
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.0),
                    ),
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: 10),
                CSCPicker(
                  defaultCountry: CscCountry.Indonesia,
                  onCountryChanged: (value) {
                    setState(() {
                      countryValue = _extractCountryName(value);
                    });
                  },
                  onStateChanged: (value) {
                    setState(() {
                      stateValue = value;
                    });
                  },
                  onCityChanged: (value) {
                    setState(() {
                      cityValue = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                String venue = venueController.text;
                String address = addressController.text;

                if (address.isNotEmpty &&
                    cityValue != null &&
                    countryValue != null) {
                  _firestore.collection('locations').add({
                    'locationAddress': address,
                    'city': cityValue,
                    'country': countryValue,
                  });

                  venueController.clear();
                  addressController.clear();
                  setState(() {
                    cityValue = '';
                    countryValue = '';
                  });

                  Navigator.of(context).pop(); // Close the dialog.
                }
              },
              child: Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 230, 0, 0),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog.
              },
              child: Text('Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 230, 0, 0),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteLocation(String locationId) {
    _firestore.collection('locations').doc(locationId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Location Management'),
          backgroundColor: Color.fromARGB(255, 230, 0, 0)),
      body: Column(
        children: [
          StreamBuilder(
            stream: _firestore.collection('locations').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              var locations = snapshot.data?.docs;

              List<Widget> locationWidgets = [];
              for (var location in locations!) {
                var locationData = location.data() as Map<String, dynamic>;
                String locationId = location.id;
                String address = locationData['locationAddress'];
                String city = locationData['city'];
                String country = locationData['country'];

                var locationWidget = ListTile(
                  title: Text('Address: $address'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('City: $city'),
                      Text('Country: $country'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteLocation(locationId),
                  ),
                );
                locationWidgets.add(locationWidget);
              }

              return Expanded(
                child: ListView(
                  children: locationWidgets,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateLocationMenu(context),
        child: Icon(Icons.add),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
    );
  }
}
