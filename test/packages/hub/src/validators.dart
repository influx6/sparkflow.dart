part of hub;

class Valids{

  @deprecated
  static bool iS(n,m) => match(n,m);
  
  static bool match(n,m){ return !!(n == m); }  
  static bool not(bool m){ return !m; }
  static bool isNot(n,m){ return Valids.not(Valids.match(n,m)); }
  static bool isString(a) => a is String;
  static bool isNum(a) => a is num;
  static bool isInt(a) => a is int;
  static bool isBool(a) => a is bool;
  static bool isFunction(a) => a is Function;
  static bool isMap(a) => a is Map;
  static bool isList(a) => a is List;
  static bool exist(a) => Valids.not(Valids.match(a,null));
  static bool notExist(a){ return Valids.not(Valids.exist(a)); }
  static Function isTrue = (a){ return (Valids.isBool(a) && a == true); };
  static Function isFalse = (a){ return (Valids.isBool(a) && a == false); };

  
}
