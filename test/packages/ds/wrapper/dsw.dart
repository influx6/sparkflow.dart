library ds.wrapper;

import 'dart:mirrors';

part '../helpers.dart';
part 'dswabstract.dart';
part 'dswmap.dart';
part 'dswlist.dart';

class dsStorage{
		
	static createMap(){
		return new dsMapStorage();
	}
	
	static createList(){
		return new dsListStorage();
	}
}



