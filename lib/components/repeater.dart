library flow.utils;

import 'package:flow/flow.dart';

class Repeater extends Component{

  static create([String id]) => new Repeater(id);
  
  Repeater([String id]): super((id != null ? id : "Repeater")){
    this.meta.update('desc','a simple synchronous repeater component');
    this.makePort('in');
    this.makePort('out');
    this.loopPorts('in','out');
  }
  
  
}

class Prefixer extends Component{
  final _buffer = new StringBuffer();
  String _prefix='';

  static create([String id]) => new Prefixer(id);

  Prefixer([String id]): super(id != null ? id : "Prefixer"){
    this.meta.update('desc','prefixing a value to a IP');
    this.makePort('in');
    this.makePort('out');
    this.init();
  }

  void init(){
    var i = this.getPort('in');
    var o = this.getPort('out');
    var m = this.getPort('option');
	var stream = m.stream;
    
    stream.listen((_){ this._prefix = _; });
	stream.onDrain((){
		print(this._prefix);
		i.listen((n){
			this._buffer.write(this._prefix);
			this._buffer.write(n);
			o.send(this._buffer.toString());
			this._buffer.clear();
		});
		stream.offDrain();
	});
	
  }

}

