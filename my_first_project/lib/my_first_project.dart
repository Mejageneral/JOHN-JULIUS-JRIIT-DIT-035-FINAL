import 'dart:io';
import 'package:mysql1/mysql1.dart';
import 'dart:convert'; 

late MySqlConnection conn;

void main() async {
  try {
    await initializeDatabase();
    await userRegistration();
    await displayMenu();
  } catch (e) {
    print('Error: $e');
    exitApp(); 
  }
}

Future<void> initializeDatabase() async {
  conn = await MySqlConnection.connect(ConnectionSettings(
    host: '127.0.0.1', 
    port: 3306,
    user: 'root',
    password: '12345', 
    db: 'dartandmysql',
  ));
}

Future<void> userRegistration() async {
  print("\nWelcome to the USSD Registration");

  print("Please enter a username: ");
  String? username = stdin.readLineSync();

  print("Please enter a password: ");
  String? password = stdin.readLineSync();

  String hashedPassword = generatePasswordHash(password!);

  await conn.query(
    'INSERT INTO user_balance (username, password, credit_balance, wallet_balance) VALUES (?, ?, ?, ?)',
    [username, hashedPassword, 100.0, 50.0],
  );

  print("Registration complete! Welcome, $username.");
}

Future<Map<String, dynamic>> fetchBalances(int id) async {
  try {
    var results = await conn.query('SELECT credit_balance, wallet_balance, password FROM user_balance WHERE id = ?', [id]);

    if (results.isNotEmpty) {
      var row = results.first;
      return {
        'credit_balance': row['credit_balance'] ?? 0.0,  
        'wallet_balance': row['wallet_balance'] ?? 0.0,  
        'password': row['password'] ?? '',               
      };
    }

    return {
      'credit_balance': 0.0,
      'wallet_balance': 0.0,
      'password': '',
    };

  } catch (e) {
    print("Error fetching balances: $e");
    return {
      'credit_balance': 0.0,
      'wallet_balance': 0.0,
      'password': '',
    };
  }
}

Future<void> updateBalances(int id, double newCredit, double newWallet) async {
  await conn.query(
    'UPDATE user_balance SET credit_balance = ?, wallet_balance = ? WHERE id = ?',
    [newCredit, newWallet, id],
  );
}

String generatePasswordHash(String password) {
  var bytes = utf8.encode(password); 
  return base64.encode(bytes); 
}

bool verifyPassword(String inputPassword, String storedHash) {
  var inputHash = generatePasswordHash(inputPassword);
  return inputHash == storedHash;
}

Future<void> displayMenu() async {
  print("\nWelcome to the USSD Menu:");
  print("1. Check Balance");
  print("2. Buy Data");
  print("3. Recharge");
  print("4. Exit");
  print("Enter your choice: ");

  String? choice = stdin.readLineSync();

  switch (choice) {
    case '1':
      await checkBalance();
      break;
    case '2':
      await buyData();
      break;
    case '3':
      await recharge();
      break;
    case '4':
      exitApp();
      break;
    default:
      print("You have entered an incorrect statement.");
      exitApp(); 
  }
}

Future<void> checkBalance() async {
  print("Please enter your ID: ");
  int? id = int.tryParse(stdin.readLineSync() ?? '');

  if (id == null) {
    print("Invalid ID.");
    exitApp();
  }

  var balances = await fetchBalances(id!);
  print("Your credit balance is \$${balances['credit_balance']?.toStringAsFixed(2)}.");
  print("Your wallet balance is \$${balances['wallet_balance']?.toStringAsFixed(2)}.");
  await displayMenu();
}

Future<void> buyData() async {
  print("Please enter your ID: ");
  int? id = int.tryParse(stdin.readLineSync() ?? '');

  if (id == null) {
    print("Invalid ID.");
    exitApp();
  }

  var balances = await fetchBalances(id!);

  if (balances['credit_balance'] == 0.0 && balances['wallet_balance'] == 0.0) {
    print("Your balance is 0. Please recharge.");
    await displayMenu();
    return;
  }

  print("Please enter your username: ");
  stdin.readLineSync();

  print("Please enter your password: ");
  String? inputPassword = stdin.readLineSync();

  if (!verifyPassword(inputPassword ?? '', balances['password'])) {
    print("Invalid password. Please try again.");
    exitApp(); 
  }

  print("Select Data Plan:");
  print("1. 500MB for \$5");
  print("2. 1GB for \$10");
  print("3. 2GB for \$15");
  print("Enter your choice: ");

  String? dataChoice = stdin.readLineSync();
  double price = 0;

  switch (dataChoice) {
    case '1':
      price = 5.0;
      break;
    case '2':
      price = 10.0;
      break;
    case '3':
      price = 15.0;
      break;
    default:
      print("You have entered an incorrect statement.");
      exitApp(); 
  }

  await choosePaymentMethod(id, price, balances['credit_balance']!, balances['wallet_balance']!);
}

Future<void> choosePaymentMethod(int id, double price, double creditBalance, double walletBalance) async {
  print("Choose payment method:");
  print("1. Use Credit (Balance: \$${creditBalance.toStringAsFixed(2)})");
  print("2. Use Wallet (Balance: \$${walletBalance.toStringAsFixed(2)})");
  print("Enter your choice: ");

  String? paymentChoice = stdin.readLineSync();

  switch (paymentChoice) {
    case '1':
      if (creditBalance >= price) {
        creditBalance -= price;
        print("You have successfully purchased the data using your credit.");
      } else {
        print("Insufficient credit balance.");
      }
      break;
    case '2':
      if (walletBalance >= price) {
        walletBalance -= price;
        print("You have successfully purchased the data using your wallet.");
      } else {
        print("Insufficient wallet balance.");
      }
      break;
    default:
      print("You have entered an incorrect statement.");
      exitApp(); 
  }

  await updateBalances(id, creditBalance, walletBalance);
  await displayMenu();
}

Future<void> recharge() async {
  print("Please enter your ID: ");
  int? id = int.tryParse(stdin.readLineSync() ?? '');

  if (id == null) {
    print("Invalid ID.");
    exitApp();
  }

  var balances = await fetchBalances(id!);
  double creditBalance = balances['credit_balance']!;

  print("Enter recharge amount: ");
  String? amount = stdin.readLineSync();
  double rechargeAmount = double.tryParse(amount ?? '') ?? 0;

  if (rechargeAmount > 0) {
    creditBalance += rechargeAmount;
    print("You have successfully recharged \$${rechargeAmount.toStringAsFixed(2)}.");
    await updateBalances(id, creditBalance, balances['wallet_balance']!);
  } else {
    print("You have entered an incorrect statement.");
    exitApp();
  }

  await displayMenu();
}

void exitApp() {
  print("Thank you for using our service. Goodbye!");
  exit(0);
}
