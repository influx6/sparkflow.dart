library flow.specs;

import 'package:sparkflow/components/transformers.dart';

void main(){
  
  var prefixer = StringPrefixer.create();
  
  prefixer.port('outports:out').tap((n){
    print('prexifing: $n');
    n.free();
  });
  
  prefixer.port('inports:in').send('one');
  
  prefixer.port('static:option').send('tag::');
  
  prefixer.port('inports:in').send('two');

  prefixer.port('inports:in').send('three');

  prefixer.port('static:option').send('rat::');

  prefixer.port('inports:in').send('four');

}
