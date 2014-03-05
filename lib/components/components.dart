library sparkflow.components;

import 'package:sparkflow/sparkflow.dart';
import 'package:sparkflow/components/unmodifiers.dart';
import 'package:sparkflow/components/transformers.dart';
import 'package:sparkflow/components/groupers.dart';

//this is a necessity and should be declared either as a static function in the class,to 
//add the necessary components to the SparkRegistery,unforunately there is no easy way
//to automatically run this once a library is imported;
class Components{
  
  static void registerComponents(){
    Component.registerComponents();
	UnModifiers.registerComponents();
	Transformers.registerComponents();
	Groupers.registerComponents();
  }
  
}