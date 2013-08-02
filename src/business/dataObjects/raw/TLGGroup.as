package business.dataObjects.raw
{
	import mx.collections.ArrayCollection;
	
	import spark.collections.Sort;
	import spark.collections.SortField;

	public class TLGGroup
	{
		
		public var _key:String;
		[Bindable] public var _name:String;
		[Bindable] public var _admin:Boolean = false;
		[Bindable] public var _member:Boolean = false;
		public var _loaded:Boolean = false;
		[Bindable] public var _activities:ArrayCollection;
		[Bindable] public var _invites:ArrayCollection;
		
		public function TLGGroup()
		{
			_activities = new ArrayCollection( [] );
			_invites = new ArrayCollection( [] );
			
			
			//set sort for _activities and _invites
			var sortField:SortField = new SortField();
			sortField.name = '_name';
			var dataSort:Sort = new Sort();
			dataSort.fields = [sortField];
			_activities.sort = dataSort;
			_activities.refresh();

			var sortField2:SortField = new SortField();
			sortField2.name = '_email';
			var dataSort2:Sort = new Sort();
			dataSort2.fields = [sortField2];
			_invites.sort = dataSort2;
			_invites.refresh();
		}
	}
}