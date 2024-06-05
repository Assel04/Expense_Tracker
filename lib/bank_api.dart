import 'package:http/http.dart' as http;
import 'dart:convert';

// Fetch transactions from Kaspi Bank API
Future<void> fetchKaspiTransactions() async {
  String kaspiApiUrl = 'https://kaspi.kz/';
  try {
    final response = await http.get(Uri.parse(kaspiApiUrl));
    if (response.statusCode == 200) {
      // Parse and process transaction data from response
      var jsonData = json.decode(response.body);
      // Process the data accordingly
    } else {
      throw Exception('Failed to load Kaspi Bank transactions');
    }
  } catch (e) {
    print('Error fetching Kaspi Bank transactions: $e');
    throw Exception('Failed to load Kaspi Bank transactions');
  }
}

// Fetch transactions from Halik Bank API
Future<void> fetchHalikTransactions() async {
  String halikApiUrl = 'https://halykbank.kz/';
  try {
    final response = await http.get(Uri.parse(halikApiUrl));
    if (response.statusCode == 200) {
      // Parse and process transaction data from response
      var jsonData = json.decode(response.body);
      // Process the data accordingly
    } else {
      throw Exception('Failed to load Halik Bank transactions');
    }
  } catch (e) {
    print('Error fetching Halik Bank transactions: $e');
    throw Exception('Failed to load Halik Bank transactions');
  }
}
