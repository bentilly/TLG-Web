package business.dataObjects
{
	import mx.collections.ArrayCollection;

	public class TlgGroup
	{
		
		[Bindable] public var _name:String;
		[Bindable] public var _key:String;
		[Bindable] public var _admin:Boolean = false; //set to true if current user is admin of this group
		[Bindable] public var _member:Boolean = false; //set to true if current user is member of this group
		[Bindable] public var _members_collection:ArrayCollection; //Collection of GroupMemper objects
		[Bindable] public var _activities_collection:ArrayCollection; //Collection of Activity objects
		
		//flags
		public var _loaded:Boolean = false; //set to true when all data is loaded. Doesnt request data on second look
		
		public function TlgGroup(name:String, key:String)
		{
			_name = name;
			_key = key;
			_activities_collection = new ArrayCollection( [] );
			_members_collection = new ArrayCollection( [] );
		}
		
		public function addActivity(a:Activity):void{
			_activities_collection.addItem(a);
		}
		public function addMember(data:Object):void{
			var m:GroupMember = new GroupMember(data.name);
			m._group = this;
			if(data.currentUser == 'true'){
				m._currentUser = true;
			}
			m.buildWorkoutDays(data);
			_members_collection.addItem(m);
		}
		public function rebuildLeaderboardData(start:Date, end:Date):void{
			//Cant iterate through the collection as it will sort as it goes, missing some and getting some >1.
			//break out the array and iterate throuh that instead
			var temp_members_array:Array = _members_collection.toArray();
			for each(var m:GroupMember in temp_members_array){ 
				m.lbStartDate = start;
				m.lbEndDate = end;
				m.buildLeaderboardData(start, end);
				
			}
		}
	}
}