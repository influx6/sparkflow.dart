import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:hub/hub.dart';
import 'package:path/path.dart' as paths;
import 'package:streamable/streamable.dart' as sm;

class GuardedFile{
	MapDecorator options;
	Switch writable;
	File f;

	static create(n,m) => new GuardedFile(path:n,readonly:m);

	GuardedFile({String path, bool readonly: false}){
		this.options = new MapDecorator.from({'readonly': readonly, 'path':path});
		this.f = new File(this.options.get('path'));
		this.writable = Switch.create();
		if(!readonly) this.writable.switchOn();
	}
  
	Future fsCheck(String path){
		return new Future.value((FileSystemEntity.typeSync(path) == FileSystemEntityType.NOT_FOUND ? new Exception('NOT FOUND!') : path));
	}

	Future rename(String name){
		if(!this.writable.on()) return null;
		return this.f.rename(name);
	}

	dynamic renameSync(String name){
		if(!this.writable.on()) return null;
		return this.f.rename(name);
	}

	Future open(FileMode mode){
		if(!this.writable.on() && (mode == FileMode.WRITE || mode == FileMode.APPEND)) return null;
		return this.f.open(mode:mode);
	}

	dynamic openSync(FileMode mode){
		if(!this.writable.on() && (mode == FileMode.WRITE || mode == FileMode.APPEND)) return null;
		return this.f.openSync(mode:mode);
	}

	dynamic openRead([int start,int end]){
		return this.f.openRead(start,end);
	}

	dynamic openWrite([FileMode mode, Encoding encoding]){
		if(!this.writable.on()) return null;
		return this.f.openWrite(mode:Hub.switchUnless(mode, FileMode.WRITE),encoding:Hub.switchUnless(encoding, UTF8));
	}
	
	dynamic openAppend([Encoding encoding]){
	  return this.openWrite(FileMode.APPEND,encoding);
	}

	Future readAsBytes(){
		return this.f.readAsBytes();
	}

	dynamic readAsBytesSync(){
		return this.f.readAsBytesSync();
	}

	Future readAsLines([Encoding enc]){
		return this.f.readAsBytes();
	}

	dynamic readAsLinesSync([Encoding enc]){
		return this.f.readAsBytesSync();
	}

	Future readAsString([Encoding enc]){
		return this.f.readAsString(encoding: Hub.switchUnless(enc, UTF8));
	}

	dynamic readAsStringSync([Encoding enc]){
		return this.f.readAsStringSync(encoding: Hub.switchUnless(enc, UTF8));
	}

	Future writeAsString(String contents, [FileMode mode, Encoding encoding]){
		if(!this.writable.on()) return null;
		return this.f.writeAsString(contents,mode: Hub.switchUnless(mode, FileMode.WRITE),encoding: Hub.switchUnless(encoding, UTF8));
	}
  
	dynamic appendAsString(String contents,[Encoding enc]){
	  return this.writeAsString(contents, FileMode.APPEND, enc);
	}
	
	dynamic writeAsStringSync(String contents, [FileMode mode, Encoding encoding]){
		if(!this.writable.on()) return null;
		return this.f.writeAsStringSync(contents,mode: Hub.switchUnless(mode, FileMode.WRITE),encoding: Hub.switchUnless(encoding, UTF8));
	}

	dynamic appendAsStringSync(String contents,[Encoding enc]){
	    return this.writeAsStringSync(contents, FileMode.APPEND, enc);
	}
	 
	Future writeAsBytes(List<int> bytes, [FileMode mode]){
		if(!this.writable.on()) return null;
		return this.f.writeAsBytes(bytes,mode: Hub.switchUnless(mode, FileMode.WRITE));
	}
  
	dynamic appendAsBytes(List<int> bytes){
	  return this.writeAsBytes(bytes, FileMode.APPEND);
	}
	
	dynamic writeAsBytesSync(List<int> bytes, [FileMode mode]){
		if(!this.writable.on()) return null;
		return this.f.writeAsBytesSync(bytes,mode: Hub.switchUnless(mode, FileMode.WRITE));
	}

  	dynamic appendAsBytesSync(List<int> bytes){
	    return this.writeAsBytesSync(bytes, FileMode.APPEND);
	}
	 
	Future delete([bool r]){
		if(!this.writable.on()) return null;
		return this.f.delete(recursive: Hub.switchUnless(r,true));
	}

	void deleteSync([bool r]){
		if(!this.writable.on()) return null;
		return this.f.deleteSync(recursive: Hub.switchUnless(r,true));
	}

	Future exists(){
		return this.f.exists();
	}

	bool existsSync(){
		return this.f.existsSync();
	}

	Future stat(){
		return this.f.stat();
	}

	dynamic statSync(){
		return this.f.statSync();
	}

	String get path => this.f.path;

	dynamic get lastModified => this.f.lastModified();
	dynamic get lastModifiedSync => this.f.lastModifiedSync();

	dynamic get length => this.f.length();
	dynamic get lengthSync => this.f.lengthSync();

	bool get isWritable => this.writable.on();
	bool get isFile => true;
}

class GuardedDirectory{
	MapDecorator options;
	Switch writable;
	Directory d;
	dynamic dm;
  
	static create(n,m) => new GuardedDirectory(path:n,readonly:m);
	
	GuardedDirectory({String path, bool readonly: false}){
    this.options = new MapDecorator.from({'readonly':readonly, 'path':path});
		this.d = new Directory(this.options.get('path'));
		this.writable = Switch.create();
		if(!readonly) this.writable.switchOn();
	}

	Future fsCheck(String path){
		return new Future.value((FileSystemEntity.typeSync(path) == FileSystemEntityType.NOT_FOUND ? new Exception('NOT FOUND!') : path));
	}

	dynamic createDirSync([bool f]){
	    if(!this.writable.on() && !this.d.existsSync()) return null;
	    this.d.create(recursive: Hub.switchUnless(f, true));
	    return this;
	}
	  
	Future createDir([bool f]){
	    if(!this.writable.on() && !this.d.existsSync()) return null;
	    return this.d.create(recursive:  Hub.switchUnless(f, true)).then((_){ return this; });
	}
	  
	dynamic File(String path){
	    var root = paths.join(this.options.get('path'),path);
	    return GuardedFile.create(root, this.options.get('readonly'));
	}
  
	dynamic list([bool rec,bool ffl]){
		return this.d.list(recursive: Hub.switchUnless(ffl, false),followLinks: Hub.switchUnless(ffl, true));
	}

	dynamic listSync([bool rec,bool ffl]){
		return this.d.listSync(recursive: Hub.switchUnless(ffl, false),followLinks: Hub.switchUnless(ffl, true));
	}

	sm.Streamable directoryLists([Function transform, bool rec,bool ff]){
	    var transformed = sm.Streamable.create();
	    var fn = Hub.switchUnless(transform, (_){ return _; }); 
	    transformed.transformer.on((n){ return n.path; });
	    this.list(rec,ff).listen(transformed.emit,onDone:(){ 
	    	transformed.end(); 
	    });
	    return transformed;
	}
	 
  	sm.Streamable directoryListsAsString([bool rec,bool ff]){
    return this.directoryLists((o){ return o.path;},rec,ff); 
  	}
  
	Future rename(String name){
		if(!this.writable.on()) return null;
		return this.d.rename(name);
	}

	dynamic renameSync(String name){
		if(!this.writable.on()) return null;
		return this.d.rename(name);
	}

	Future createNewDir(String name,[bool r]){
	    var root = paths.join(this.options.get('path'),name);
    	var dir = GuardedDirectory.create(root,this.options.get('readonly'));
    	return dir.createDir(r).then((j){ return dir; });
	}

	dynamic createNewDirSync(String name,[bool r]){
	    var root = paths.join(this.options.get('path'),name);
		var dir = GuardedDirectory.create(root,this.options.get('readonly'));
		dir.createDirSync(r);
		return dir;
	}

	Future createTemp(String name){
		if(!this.writable.on()) return null;
		return this.d.createTemp(name);
	}

	dynamic createTempSync(String name){
		if(!this.writable.on()) return null;
		return this.d.createTempSync(name);
	}

	Future delete([bool r]){
		if(!this.writable.on()) return null;
		return this.d.delete(recursive: Hub.switchUnless(r,true));
	}

	void deleteSync([bool r]){
		if(!this.writable.on()) return null;
		return this.d.deleteSync(recursive: Hub.switchUnless(r,true));
	}

	Future exists(){
		return this.d.exists();
	}

	bool existsSync(){
		return this.d.existsSync();
	}

	Future stat(){
		return this.d.stat();
	}

	dynamic statSync(){
		return this.d.statSync();
	}

	bool get isWritable => this.writable.on();

	String get path => this.d.path;

	bool get isDirectory => true;
}


class GuardedFS{
  final cache = Hub.createMapDecorator();
  GuardedDirectory dir;


  	static create(p,r) => new GuardedFS(p,r);
  	
	GuardedFS(String path,bool readonly){
		this.dir = GuardedDirectory.create(path,readonly);
	}

	Future fsCheck(String path){
		return new Future.value((FileSystemEntity.typeSync(path) == FileSystemEntityType.NOT_FOUND ? new Exception('NOT FOUND!') : path));
	}
	
	dynamic File(String path){
		if(this.cache.storage.length > 100) this.cache.flush();
		var dir = this.cache.get(path);
		if(dir != null && dir is GuardedFile) return dir; 
		dir = this.dir.File(path);
		this.cache.add(path,dir);
		return dir;
	}

	dynamic Dir(String path,[bool rec]){
		if(this.cache.storage.length > 100) this.cache.flush();
		var dir = this.cache.get(path);
		if(dir != null && dir is GuardedDirectory) return new Future.value(dir); 
		dir = this.dir.createNewDir(path,rec);
		return dir.then((_){
		   this.cache.add(path,_);
		   return _; 
		});
	}

	dynamic directoryLists([String path,Function transform, bool rec,bool ff]){
	  var dir = (path != null ? this.Dir(path,rec) : new Future.value(this.dir));
	  return dir.then((_){
	     return _.directoryLists(transform,rec,ff);
	  });
	}

	dynamic directoryListsAsString([String path, bool rec,bool ff]){
    var dir = (path != null ? this.Dir(path,rec) : new Future.value(this.dir));
    return dir.then((_){
       return _.directoryListsAsString(rec,ff);
    });	
  }
	
	bool get isWritable => this.dir.isWritable;
	
}