library sparkflow.spec;

import 'dart:html';
import 'package:sparkflow/runtime/messageruntime.dart';

void main(){

	var socket = PostMessageRuntime.create(window);
  
	print(socket.root);
}