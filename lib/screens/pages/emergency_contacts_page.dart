import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';

class EmergencyContactsPage extends StatefulWidget {
  @override
  _EmergencyContactsPageState createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<Map<String, dynamic>> emergencyContacts = [];
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
  }

  Future<void> createEmergencyContact(String name, String mobileNo) async {
    final accessToken = await storage.read(key: 'access_token');
    final url = 'https://supernova-fqn8.onrender.com/api/main/create-contact/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name, 'mobile_no': mobileNo}),
      );

      if (response.statusCode == 201) {
        final contactData = jsonDecode(response.body);
        setState(() {
          emergencyContacts.add(contactData);
        });
        showSnackBar('Emergency contact added successfully.', isError: false);
      } else {
        showSnackBar('Failed to add emergency contact. Please try again.');
      }
    } catch (error) {
      showSnackBar('Error adding emergency contact. Please try again later.');
    }
  }

  Future<void> _addContactFromPhonebook() async {
    if (await Permission.contacts.request().isGranted) {
      try {
        final Contact? contact = await ContactsService.openDeviceContactPicker();
        if (contact != null) {
          if (emergencyContacts.length < 5) {
            final name = contact.displayName ?? '';
            final mobileNo = contact.phones?.first.value ?? '';
            setState(() {
              emergencyContacts.add({'name': name, 'mobile_no': mobileNo});
            });
            await createEmergencyContact(name, mobileNo);
          } else {
            showSnackBar('You can only add up to 5 contacts.');
          }
        }
      } catch (e) {
        showSnackBar('Error picking contact. Please try again.');
      }
    } else {
      showSnackBar('Contact permission not granted.');
    }
  }

  void _showDeleteConfirmationBottomSheet(int index) {
    final contact = emergencyContacts[index];
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to delete "${contact['name']}"?',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the bottom sheet
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Cancel'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        emergencyContacts.removeAt(index);
                      });
                      Navigator.pop(context); // Close the bottom sheet
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Emergency Contacts'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (emergencyContacts.length < 5)
            IconButton(
              icon: Icon(Icons.add, color: Colors.purple),
              color: Colors.purple,
              onPressed: _addContactFromPhonebook,
            ),
          TextButton(
            onPressed: () {
              // Navigate to the "/homepage" route
              Navigator.pushReplacementNamed(context, '/homepage');
            },
            child: Text(
              'Skip for Now',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.0),
            Text(
              'Add up to 5 contacts',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount: emergencyContacts.length,
                itemBuilder: (context, index) {
                  final contact = emergencyContacts[index];
                  return ListTile(
                    title: Text(contact['name']),
                    subtitle: Text(contact['mobile_no']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.grey),
                      onPressed: () {
                        _showDeleteConfirmationBottomSheet(index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}