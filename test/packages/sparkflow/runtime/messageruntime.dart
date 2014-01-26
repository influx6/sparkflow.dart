library sparkflow.runtimes;

import 'dart:async';
import 'dart:html';
import 'package:hub/hub.dart';
import 'package:streamable/streamable.dart';
import 'package:sparkflow/sparkflow.dart';


class PostMessageRuntime extends MessageRuntime{
	dynamic iframePortal;

	static create(m,[id,tf]) => new PostMessageRuntime(m,id,tf);

	PostMessageRuntime(dynamic m,[String iframeId,bool ce]): super(m,ce){
		this.options.add('id',(iframeId == null ? 'networkFrame' : iframeId));

		this.iframePortal = new IFrameElement();
		if(iframeId != null) 
			this.iframePortal.setAttribute('id',this.options.get('id'));
	}

	void bindOutStream(){
		this.outMessages.on((message){
			this.root.postMessage(message['data'],message['target'].href,message['ports']);
		});
	}

	void bindInStream(){
		this.root.addEventListener('message',(e){
			var message = e.data;

			print('messageInStream: $message : $e');
			if(e.data['protocol'] == null && e.data['command'] == null) return;

			this.inMessages.emit({'event': e, data: e.data});
		},false);
	}

	void bindErrorStream(){
		this.root.addEventListener('error',(e){
			this.send('network','error',{ 'payload': e.toString() });
		});
	}

}

class SocketMessageRuntime extends MessageRuntime{
	
	static create(m,[ce]) => new SocketMessageRuntime(m,ce);

	SocketMessageRuntime(WebSocket m,[ce]): super(m,ce);

	void bindOutStream(){
		this.outMessages.on((message){
			//this.root.postMessage(message['data'],message['target'].href,message['ports']);
		});
	}

	void bindInStream(){
		this.root.addEventListener('message',(e){
			// var message = e.data;

			// print('messageInStream: $message : $e');
			// if(e.data['protocol'] == null && e.data['command'] == null) return;

			// this.inMessages.emit({'event': e, data: e.data});
		},false);
	}

	void bindErrorStream(){
		this.root.addEventListener('error',(e){
			this.send('network','error',{ 'payload': e.toString() });
		});
	}
}