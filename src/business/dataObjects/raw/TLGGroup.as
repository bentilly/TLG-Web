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
		
		public function TLGGroup()
		{
			_activities = new ArrayCollection( [] );
			
			//set sort for _activities
			var sortField:SortField = new SortField();
			sortField.name = '_name';
			var dataSort:Sort = new Sort();
			dataSort.fields = [sortField];
			_activities.sort = dataSort;
			_activities.refresh();
		}
	}
}