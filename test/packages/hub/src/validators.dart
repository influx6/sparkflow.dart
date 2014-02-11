part of hub;

class Valids{

	static bool iS(n,m){ 
	  return !!(n == m);
	}

	static bool not(bool m){
		return !m;
	}
	
	static Function isNot = Funcs.compose(Valids.not,Valids.iS,2);
	
  static bool isString(a) => a is String;
  static bool isNum(a) => a is num;
  static bool isInt(a) => a is int;
  static bool isBool(a) => a is bool;
  static bool isFunction(a) => a is Function;
  static bool isMap(a) => a is Map;
  static bool isList(a) => a is List;
 
  static bool exists(a) => a != null;
  
  static Function isTrue = (a){ return (Valids.isBool(a) && a == true); };
  static Function isFalse = (a){ return (Valids.isBool(a) && a == false); };

  
}