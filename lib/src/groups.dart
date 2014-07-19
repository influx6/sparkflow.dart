part of sparkflow;



class MassTree extends hub.MapDecorator{
  final canDestroy = hub.Switch.create();

  static create() => new MassTree();

  MassTree();

  dynamic destroy(String key){
    if(!this.canDestroy.on()) return null;
    return super.destroy(key);
  }

  void addAll(Map n){
    n.forEach((n,k){
      this.add(n,k);
    });
  }
}


class ComponentGroup{
	final groups = new hub.MapDecorator();
	final String uuid = hub.Hub.randomString(7);
	String id;

	static create(id) => new ComponentGroup(id);

	ComponentGroup(this.id);

	void add(String handle,Function generator){
	  	handle = handle.toLowerCase();
		if(this.groups.has(handle)) return null;

		var path = this.id+"/"+handle;
		this.groups.add(handle,([List ops,Map named]){
			ops = hub.Funcs.switchUnless(ops,[]);
			named = hub.Funcs.switchUnless(named,{});
			var com = Function.apply(generator,ops,hub.Hub.encryptNamedArguments(named));
			if(com is! FlowComponent) throw new Exception('$com is not a type of ${FlowComponent}');

			com.setGroup(path);
			return com;
		});
	}

	Function get(String handle){
    	handle = handle.toLowerCase();
		return this.groups.get(handle);
	}

	bool has(String handle){
    	handle = handle.toLowerCase();
		return this.groups.has(handle);
	}

	void eject(String handle){
    	handle = handle.toLowerCase();
		if(!this.groups.has(handle)) return;
		this.groups.destroy(handle);
	}
	
	String toString(){
	    return this.groups.toString();
	}

	List get toNames{
		return this.groups.storage.keys.toList();
	}
}


//SparkGroups provides a means of 
class SparkGroups{
	final groupSets = MassTree.create();

	static create() => new SparkGroups();

	SparkGroups();

	void enableRemove(){
		this.groupSets.canDestroy.switchOn();
	}

	void disableRemove(){
		this.groupSets.canDestroy.switchOff();
	}

	/*
		{
			transformers: ['StringPrefixer']
		}
	*/
	Map get toGroupMeta{
		var mapped = {};
		this.groupSets.storage.forEach((n,k){
			mapped[n] = k.toNames;
		});

		return mapped;
	}

	/*
		['transformers/StringPrefixer']		
	*/
	List get toAddressMeta{
		var mapped = [];
		this.groupSets.storage.forEach((n,k){
			k.toNames.forEach((j){
				mapped.add(n+"/"+j);
			});
		});

		return mapped;
	}

	// transformers
	void addGroup(String handle){
	  handle = handle.toLowerCase();
		if(this.groupSets.has(handle)) return null;
		this.groupSets.add(handle,ComponentGroup.create(handle));
	}
	
	ComponentGroup getGroup(String handle){
	  handle = handle.toLowerCase();
		if(this.hasGroup(handle)) return this.groupSets.get(handle);
		return null;
	}

	bool hasGroup(String handle){
	  handle = handle.toLowerCase();
		return this.groupSets.has(handle);
	}

	//transformers, StringPrefixer,[id,name],{id:name}
	dynamic generate(String handle,String type,[List ops,Map a]){
	   handle = handle.toLowerCase();
	   type = type.toLowerCase();
		var group = this.getGroup(handle);
		if(group == null || !group.has(type)) return null;
		return group.get(type)(ops,a);
	}


	//remove transformers;
	ComponentGroup removeGroup(String handle){
    	handle = handle.toLowerCase();
		if(!this.groupSets.has(handle)) return null;
		var gp = this.groupSets.get(handle);
		this.groupSets.destroy(handle);
		return gp;
	}

	// true : false => transformers/StringPrefixer
	bool hasGroupString(String path){
	  	path = path.toLowerCase();
		var from = path.split('/');
		if(from.length < 2) return null;
		var group = hub.Enums.first(from);
		var name = hub.Enums.second(from);	
		return (this.hasGroup(group) ? this.getGroup(group).has(name) : false);
	}

	// components/component
	void addUsingString(String path,Function n){
	   	path = path.toLowerCase();
		var from = path.split('/');
		if(from.length < 2) return null;
		var group = hub.Enums.first(from);
		var name = hub.Enums.second(from);
		this.addGroup(group);
		this.getGroup(group).add(name,n);
	}

	//transformers/StringPrefixer
	dynamic getGroupFromString(String path){
	   	path = path.toLowerCase();
		var from = path.split('/');
		if(from.length < 2) return null;
		if(this.hasGroup(from.first)){
			var grp = this.getGroup(hub.Enums.first(from));
			return grp.get(hub.Enums.second(from));
		}
		return null;
	}

	//transformers/StringPrefixer,[id,name],{id:name}
	dynamic generateFromString(String path,[List ops,Map a]){
	   	path = path.toLowerCase();
		var item = this.getGroupFromString(path);
		if(item != null) return item(ops,a);
		return null;
	}
	
	String toString(){
	  return this.groupSets.toString();
	}
}

