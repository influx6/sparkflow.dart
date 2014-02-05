library hub;

import 'dart:js';
import 'package:hub/hub.dart';

export 'package:hub/hub.dart';

class JStripe{
	final fragments = Hub.createMapDecorator();
	final methodfragments = Hub.createMapDecorator();
	final JsObject defaultContext = context;
	JsObject root;
	dynamic core;

	static create(s) => new JStripe(s);

	JStripe(t){
		this.core = t;
		this.root = new JsObject.fromBrowserObject(t);
		this.fragments.add('root',this.root);
	}

	void fragment(String tag){
		this.fragments.add(tag,this.root[tag]);
	}

	dynamic grabProperty(JsObject fragment,String props){
		var sets = props.split('.'), ind = 0, cur = fragment;

		while(ind < sets.length){
			if(cur == null || ind >= sets.length){
				return cur;
			}
			cur = cur[sets[ind]];
			ind += 1;
		}

		return cur;
	}

	void methodFragment(String tag,String method,[String prop]){
		if(!this.fragments.has(tag)) return;

		var fragment = this.fragments.get(tag);
		var methods = (this.methodfragments.has(tag) ? this.methodfragments.get(tag) : Hub.createMapDecorator());
		
		var inProp = (prop != null ? prop : method).toString();
  
		var mf = this.grabProperty(fragment,inProp);
		if(mf == null) return;

		methods.add(method,(List ops){
			if(mf is JsFunction) return mf.apply(ops,thisArg: fragment);
			return mf;
		});

		this.methodfragments.add(tag,methods);
	}

	dynamic runOn(String tag,String fragment,[String method]){
		if(!this.fragments.has(tag) || !this.methodfragments.has(tag)) return null;
		var methods = this.methodfragments.get(tag);
		var frag = methods.get(fragment);

		// if the argument will be a list/array, then best to do this [list/array] else,it will be flattened into argument list
		// beyond that you can simple pass the arguments as normal.
		// for muiltple values ,pass in [val1,val2,...]
		// for single value, pass in val
		return ([dynamic extra]){
			var args = new List();
			if(method != null) args.add(method);
			if(extra is List) args.addAll(extra);
			else args.add(extra);

			return frag(args);
		};
	}
  
	dynamic toDartJSON(JsObject m){
	  return context['JSON'].callMethod('stringify',[m]);  
	}
	
	dynamic toJS(dynamic m){
		return new JsObject.jsify(m);
	}

	String toString(){
		return "${this.fragments} \n ${this.methodfragments}";
	}
}
