part of hub;

class Enums{
  
  static dynamic nth(List a,int ind){
    if(ind >= a.length) return null;
    return a[ind];  
  }
  
  static dynamic first(List a){
    return Enums.nth(a,0);  
  }
  
  static dynamic second(List a){
    return Enums.nth(a,1);  
  }
  
  static dynamic third(List a){
    return Enums.nth(a,2);
  }
  
  static Function nthFor(dynamic a){
    if(a is List) return (int ind){
      if(ind >= a.length) return null;
      return a[ind];
    };
    
    if(a is Map) return (dynamic m){
      if(!a.containsKey(m)) return null;
      return a[m];
    };
    
    return null;
  }
  
  static Function indexFor(dynamic a){
    if(a is List) return (dynamic v,[int s]){
      return a.indexOf(v,s);
    };
    
    if(a is Map) return (dynamic v){
      if(!a.containsValue(v)) return null;
      var set = [];
      a.forEach((k,c){
         if(c == v) set.add(k);
      });
      
      return set;
    };
    
    return null;       
  }

  static void eachAsync(List a,Function iterator,[Function complete]){
    if(a.length <= 0){
      if(complete != null) complete(a);
      return null;    
    }
    
    var total = a.length,i = 0;
    
    a.forEach((f){
      iterator(f,i,a,(err){
          if(err){
            if(complete != null) complete(a);
            return null;
          }
          total -= 1;
          if(total <= 0){
            if(complete != null) complete(a);
            return null;
          }
      });  
      i += 1;
    });
    
  }

   static void eachAsyncMap(Map a,Function iterator,[Function complete]){
      if(a.length <= 0){
        if(complete != null) complete(a);
        return null;    
      }
      
      var total = a.length;
      
      a.forEach((f,v){
        iterator(v,f,a,(err){
          if(err){
            if(complete != null) complete(a);
            return null;
          }
          total -= 1;
          if(total <= 0){
            if(complete != null) complete(a);
            return null;
          }
      });  
    });
    
  }
   
  static void eachSyncMap(Map a,Function iterator, [Function complete]){
    if(a.length <= 0){
      if(complete != null) complete(a);
      return null;    
    }
    
    var keys = a.keys.toList();
    var total = a.length,step = 0,tapper;
        
    var fuse = (){
      var key = keys[step];
      iterator(a[key],key,a,(err){
        if(err){
          if(complete != null) complete(a);
          return null;
        }
        step += 1;
        if(step == total){
          if(complete != null) complete(a);
           return null;
        }else return tapper();
      });
    };
     
    tapper = (){ return fuse(); };

    return fuse();
  }
  
  static void eachSync(List a,Function iterator, [Function complete]){
    if(a.length <= 0){
      if(complete != null) complete(a);
      return null;    
    }
    
    var total = a.length,step = 0,tapper;
        
    var fuse = (){
      iterator(a[step],step,a,(err){
        if(err){
          if(complete != null) complete(a);
          return null;
        }
        step += 1;
        if(step == total){
          if(complete != null) complete(a);
           return null;
        }else return tapper();
      });
    };
     
    tapper = (){ return fuse(); };

    return fuse();
  }
  
  static Future captureEachFuture(dynamic a,Function validator){
    var res = [];
    
    if(a.isEmpty) return new Future.value(true);
    
    if(a is List){
      a.forEach((n){
        res.add(new Future.value(validator(n)));
      });
    }
    if(a is Map){
      a.forEach((n,v){
        res.add(new Future.value(validator(n,v)));
      });
    }
    
    return Future.wait(res);
  }
  
  static Map merge(Map a,Map b,{bool override: true}){
    var merged = new Map.from(a);
    b.forEach((n,k){
      if(!override && !!merged.containsKey(n)) return;
      merged[n] = k;
    });

    return merged;
  }
  
  static List map(dynamic m,dynamic mod(i,j,k),[Function complete]){
    var mapped = [];
    if(m is List){
      Enums.eachAsync(m,(e,i,o,fn){
         mapped.add(mod(e,i,o));
         return fn(false);
      },complete);
    }

    if(m is Map){
      Enums.eachAsyncMap(m,(e,i,o,fn){
         mapped.add(mod(e,i,o));
         return fn(false);
      },complete);
    }
    return mapped;
  }
  
  static dynamic reduce(List m,dynamic mod(m,i,j,k),[dynamic memo,Function complete,bool right]){
    var set = Valids.isTrue(right) ? m.reversed.toList() : m;
    Enums.eachAsync(set,(e,i,o,fn){
      if(memo == null) memo = e;
      else memo = mod(memo,e,i,o);
      fn(false);
    },(o){
      if(complete != null) complete(memo);
    });
    
    return memo;
  }
  
  static dynamic reduceRight(List m,dynamic mod(m,i,j,k),[dynamic memo,Function complete]){
    return Enums.reduce(m,mod,memo,complete,true);
  }
  
  static List filterValues(dynamic m,bool mod(i,j,k),[Function complete]){
    var mapped = [];

    if(m is List){
      Enums.eachAsync(m,(e,i,o,fn){
         if(!!mod(e,i,o)) mapped.add(e);
         return fn(false);
      },complete);
    }

    if(m is Map){
      Enums.eachAsyncMap(m,(e,i,o,fn){
         if(!!mod(e,i,o)) mapped.add(e);
         return fn(false);
      },complete);
    }

    return mapped;
  }

  static List filterKeys(dynamic m,bool mod(i,j,k),[Function complete]){
    var mapped = [];

    if(m is List){
      Enums.eachAsync(m,(e,i,o,fn){
         if(!!mod(e,i,o)) mapped.add(i);
         return fn(false);
      },complete);
    }

    if(m is Map){
      Enums.eachAsyncMap(m,(e,i,o,fn){
         if(!!mod(e,i,o)) mapped.add(i);
         return fn(false);
      },complete);
    }

    return mapped;
  }  

  static List concat(List a,[dynamic m]){
    var sets = new List.from(a);
    if(m != null) 
      Valids.isList(m) ? sets.addAll(m) : sets.add(m);
    return sets;
  }
  
  static List mapcat(fn,List a,[Function complete]){
    return Enums.concat(Enums.map(a, fn,complete));
  }

}