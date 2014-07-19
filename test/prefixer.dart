library flow.specs;

import 'package:sparkflow/components/transformers.dart';

void main(){
  
  var prefixer = StringPrefixer.create();
  
  prefixer.port('out:out').tap((n){
    print('prexifing: $n');
  });
  
  prefixer.port('in:in').send('one');
  
  prefixer.port('static:option').send('tag::');
  
  prefixer.port('in:in').send('two');

  prefixer.port('in:in').send('three');

  prefixer.port('static:option').send('rat::');

  prefixer.port('in:in').send('four');

}
