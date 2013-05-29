package business.dataObjects
{
	import mx.collections.ArrayCollection;

	public class GroupMemberWorkoutDay
	{
		
		public var _date:Date;
		[Bindable] public var _activity_collection:ArrayCollection; //collection of ActivitySummary
		
		
		public function GroupMemberWorkoutDay()
		{
			_activity_collection = new ArrayCollection( [] );
		}
	}
}