// ignore_for_file: file_names

import 'package:mysql1/mysql1.dart';
import 'dart:async';

// ignore: non_constant_identifier_names
Future DBconnection() async {
  // ignore: await_only_futures
  var con = await ConnectionSettings(
      host: '127.0.0.1',
      port: 3306,        
      user: 'root',      
      password: '12345', 
      db: 'dartandmysql'   
  );
  
  var conn = await MySqlConnection.connect(con);
  
 
  return conn;
}


