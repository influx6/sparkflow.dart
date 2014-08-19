library spec;

import 'dart:async';
import 'package:sparkflow/sparkflow.dart';
import 'package:hub/hub.dart';

main(){
  
   Sparkflow.createRegistry("test", (r){
     
      assert(r is SparkRegistry);
      print('created registry!');
   });
}