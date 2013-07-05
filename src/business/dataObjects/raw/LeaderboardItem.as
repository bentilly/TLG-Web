package business.dataObjects.raw
{
	import mx.collections.ArrayCollection;

	public class LeaderboardItem
	{
		
		[Bindable] public var _user:TLGUser;
		[Bindable] public var _total:int;
		[Bindable] public var _activitySummaries_collection:ArrayCollection;
		
		public function LeaderboardItem()
		{
			_activitySummaries_collection = new ArrayCollection( [] );
		}
	}
}