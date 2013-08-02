package business.dataObjects.raw
{

	public class GroupMemberActivityDay
	{
		public var _date:Date;
		public var _group:TLGGroup;
		public var _user:TLGUser;
		public var _activity:Activity;
		public var _duration:int;
		
		//sorting
		public var _activityKey:String;
		public var _email:String;
		public var _groupKey:String;
		
		public function GroupMemberActivityDay()
		{
		}
	}
}