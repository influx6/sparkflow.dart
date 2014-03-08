library flow.specs;

import 'package:sparkflow/sparkflow.dart';
import 'package:sparkflow/components/transformers.dart';
import 'package:sparkflow/components/unmodifiers.dart';

void main(){
  
  var repeater = Repeater.create();
  var prefixer = StringPrefixer.create();

	var feeder = Port.create('feeder','in',{});
	var feeder2 = Port.create('feeder','in',{});
	var reader = Port.create('writer','out',{});
  
  reader.tap((n){ print('#log  => $n'); });
  
  feeder.bindPort(repeater.port('in:in'));
  repeater.port('out:out').bindPort(reader);
  
  
  feeder2.bindPort(prefixer.port('in:in'));
  prefixer.port('out:out').bindPort(reader);
  
  feeder.send('alex');
  feeder.send('i need salt!');
  feeder.beginGroup('<article>');
  feeder.send('1: road');
  feeder.endGroup('</article>');
  
  prefixer.port('static:option').send('number:');
  feeder2.send('1');
  feeder2.send('2');
  feeder2.send('4');

  //print(repeater.toMeta);
  /* var a = Component.createFrom(repeater.toMeta); */
  
}

