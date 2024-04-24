import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'expense_category.dart';

void main() => runApp(ExpenseTrackerApp());

// Class representing a transaction
class Transaction {
  final String description; // Transaction description
  final double amount; // Transaction amount
  final ExpenseCategory category; // Transaction category
  final DateTime date; // Transaction date
  bool isSelected; // Whether transaction is selected or not

  Transaction(this.description, this.amount, this.category, this.date, this.isSelected);
}

// Enumeration for filtering period
enum FilterPeriod { Day, Week, Month, Year }

// ViewModel for managing the application state
class ExpenseTrackerViewModel extends ChangeNotifier {
  double _balance = 0.0; // Current balance
  Map<ExpenseCategory, double> _categoryExpenses = {}; // Map of category expenses
  List<Transaction> _transactions = []; // List of transactions
  ExpenseCategory? _selectedFilterCategory; // Selected filter category
  Set<Transaction> _selectedTransactions = {}; // Set of selected transactions
  FilterPeriod _selectedFilterPeriod = FilterPeriod.Day; // Selected filter period

  double get balance => _balance; // Getter for balance
  Map<ExpenseCategory, double> get categoryExpenses => _categoryExpenses; // Getter for category expenses
  List<Transaction> get transactions => _transactions; // Getter for transactions
  ExpenseCategory? get selectedFilterCategory => _selectedFilterCategory; // Getter for selected filter category
  Set<Transaction> get selectedTransactions => _selectedTransactions; // Getter for selected transactions
  FilterPeriod get selectedFilterPeriod => _selectedFilterPeriod; // Getter for selected filter period

  ExpenseTrackerViewModel() {
    fetchTransactions();
  }

  // Fetch transactions from API
  Future<void> fetchTransactions() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        double totalAmount = 0.0;
        for (var data in jsonData) {
          double amount = double.parse(data['id'].toString());
          totalAmount += amount;
          _transactions.add(Transaction(data['title'], amount, ExpenseCategory('Food'), DateTime.now(), false));
        }
        _balance += totalAmount;
        _updateCategoryExpenses();
        notifyListeners();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      throw Exception('Failed to load transactions');
    }
  }

  // Update category expenses
  void _updateCategoryExpenses() {
    _categoryExpenses.clear();
    for (var transaction in _transactions) {
      _categoryExpenses.update(transaction.category, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
    }
  }

  // Add a new transaction
  void addTransaction(double amount, String description, ExpenseCategory category, DateTime date) {
    _transactions.add(Transaction(description, amount, category, date, false));
    _balance += amount;
    _updateCategoryExpenses();
    notifyListeners();
  }

  // Delete selected transactions
  void deleteTransaction() {
    for (var transaction in _selectedTransactions) {
      _balance -= transaction.amount;
      _transactions.remove(transaction);
    }
    _selectedTransactions.clear();
    _updateCategoryExpenses();
    notifyListeners();
  }

  // Toggle selection of a transaction
  void toggleTransactionSelection(Transaction transaction) {
    transaction.isSelected = !transaction.isSelected;
    if (transaction.isSelected) {
      _selectedTransactions.add(transaction);
    } else {
      _selectedTransactions.remove(transaction);
    }
    notifyListeners();
  }

  // Filter transactions by category
  void filterTransactionsByCategory(ExpenseCategory? category) {
    _selectedFilterCategory = category;
    notifyListeners();
  }

  // Filter transactions by period
  void filterTransactionsByPeriod(FilterPeriod period) {
    _selectedFilterPeriod = period;
    notifyListeners();
  }

  // Fetch analytics data from additional API
  Future<void> fetchAnalyticsData() async {
    try {
      // Perform API call to fetch analytics data
      final response = await http.get(Uri.parse(analyticsApiUrl));
      if (response.statusCode == 200) {
        // Parse response data and update analytics state
        // For example:
        // analyticsData = jsonDecode(response.body);
        // notifyListeners();
      } else {
        throw Exception('Failed to load analytics data');
      }
    } catch (e) {
      print('Error fetching analytics data: $e');
      throw Exception('Failed to load analytics data');
    }
  }
}

// Expense Tracker application widget
class ExpenseTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExpenseTrackerViewModel(),
      child: MaterialApp(
        title: 'Expense Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/',
        routes: {
          '/analytics': (context) => AnalyticsPage(),
        },
        home: ExpenseTrackerHomePage(),
      ),
    );
  }
}

// Expense Tracker home page widget
class ExpenseTrackerHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ExpenseTrackerViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Tracker'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Balance section
              Text(
                'Balance',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              Text(
                '₸ ${viewModel.balance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.0),
              // Filter by category section
              Text(
                'Filter by Category',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              DropdownButton<ExpenseCategory>(
                value: viewModel.selectedFilterCategory,
                onChanged: (ExpenseCategory? value) {
                  viewModel.filterTransactionsByCategory(value);
                },
                items: <DropdownMenuItem<ExpenseCategory>>[
                  DropdownMenuItem(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  // Generate dropdown items for expense categories
                  for (var category in ExpenseCategory.expenseCategories)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.name),
                    ),
                ],
              ),
              SizedBox(height: 20.0),
              // Show total expenses for selected category
              viewModel.selectedFilterCategory != null
                  ? Text(
                      'Total for ${viewModel.selectedFilterCategory!.name}: ₸ ${viewModel.categoryExpenses[viewModel.selectedFilterCategory] ?? 0.0}',
                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                    )
                  : Container(),
              SizedBox(height: 20.0),
              // Filter by period section
              Text(
                'Filter by Period',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              DropdownButton<FilterPeriod>(
                value: viewModel.selectedFilterPeriod,
                onChanged: (FilterPeriod? value) {
                  viewModel.filterTransactionsByPeriod(value!);
                },
                items: FilterPeriod.values.map((period) {
                  return DropdownMenuItem<FilterPeriod>(
                    value: period,
                    child: Text(period.toString().split('.').last),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.0),
              // Transactions list
              Text(
                'Transactions',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.0),
              // Display list of transactions
              ListView.builder(
                shrinkWrap: true,
                itemCount: viewModel.transactions.length,
                itemBuilder: (BuildContext context, int index) {
                  var transaction = viewModel.transactions[index];
                  return ListTile(
                    title: Text(
                      '₸ ${transaction.amount.toStringAsFixed(2)} - ${transaction.category.name}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description,
                          style: TextStyle(fontSize: 16.0),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          '${transaction.date.toString().split(' ')[0]}',
                          style: TextStyle(fontSize: 12.0, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Checkbox(
                      value: transaction.isSelected,
                      onChanged: (bool? value) {
                        viewModel.toggleTransactionSelection(transaction);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      // Floating action button to add new transaction
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to add new transaction
          showDialog(
            context: context,
            builder: (BuildContext context) {
              ExpenseCategory? selectedCategory;
              String description = '';
              double amount = 0.0;
              DateTime selectedDate = DateTime.now();

              return AlertDialog(
                title: Text('Add Transaction'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Dropdown for selecting category
                    DropdownButtonFormField<ExpenseCategory>(
                      decoration: InputDecoration(labelText: 'Category'),
                      value: selectedCategory,
                      onChanged: (ExpenseCategory? value) {
                        selectedCategory = value;
                      },
                      items: ExpenseCategory.expenseCategories.map((ExpenseCategory category) {
                        return DropdownMenuItem<ExpenseCategory>(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10.0),
                    // TextField for description
                    TextField(
                      decoration: InputDecoration(labelText: 'Description'),
                      onChanged: (String value) {
                        description = value;
                      },
                    ),
                    SizedBox(height: 10.0),
                    // TextField for amount
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Amount'),
                      onChanged: (String value) {
                        amount = double.tryParse(value) ?? 0.0;
                      },
                    ),
                    SizedBox(height: 10.0),
                    // Row for selecting date
                    Row(
                      children: [
                        Text('Date:'),
                        SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            ).then((value) {
                              if (value != null) {
                                selectedDate = value;
                              }
                            });
                          },
                          child: Text(
                            selectedDate.toString().split(' ')[0],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: <Widget>[
                  // Cancel button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  // Add button
                  TextButton(
                    onPressed: () {
                      // Add new transaction if all fields are valid
                      if (selectedCategory != null && description.isNotEmpty && amount > 0) {
                        viewModel.addTransaction(amount, description, selectedCategory!, selectedDate);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
      // Persistent footer buttons for deleting selected transactions
      persistentFooterButtons: viewModel.selectedTransactions.isNotEmpty
          ? <Widget>[
              TextButton(
                onPressed: () {
                  // Delete selected transactions
                  viewModel.deleteTransaction();
                },
                child: Text('Delete Selected'),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                ),
              ),
            ]
          : null,
      // Button for navigating to AnalyticsPage
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.analytics),
              onPressed: () {
                // Navigate to AnalyticsPage
                Navigator.pushNamed(context, '/analytics');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Analytics and reporting page widget
class AnalyticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ExpenseTrackerViewModel>(context);

    // Calculate total expenses
    double totalExpenses = viewModel.transactions.fold(0, (prev, transaction) => prev + transaction.amount);

    // Calculate total income (for demonstration purposes, assuming income is not yet implemented)
    double totalIncome = 0;

    // Calculate net balance
    double netBalance = totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Total Expenses: ₸ ${totalExpenses.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20.0),
              ),
              SizedBox(height: 10.0),
              Text(
                'Total Income: ₸ ${totalIncome.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20.0),
              ),
              SizedBox(height: 10.0),
              Text(
                'Net Balance: ₸ ${netBalance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20.0),
              ),
              SizedBox(height: 20.0),
              // Additional analytics widgets can be added here
            ],
          ),
        ),
      ),
    );
  }
}

const String apiUrl = 'https://jsonplaceholder.typicode.com/posts';
const String analyticsApiUrl = 'https://api.example.com/analytics';


// Expense category class
class ExpenseCategory {
  final String name;

  const ExpenseCategory(this.name);

  // List of expense categories
  static const List<ExpenseCategory> expenseCategories = [
    ExpenseCategory('Food'),
    ExpenseCategory('Transport'),
    ExpenseCategory('Entertainment'),
    ExpenseCategory('Utilities'),
  ];
}
