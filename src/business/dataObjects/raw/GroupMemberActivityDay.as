package business.dataObjects.raw
{
	import business.dataObjects.Activity_Data;

	public class GroupMemberActivityDay
	{
		public var _date:Date;
		public var _group:TLGGroup;
		public var _user:TLGUser;
		public var _activity:Activity_Data;
		public var _duration:int;	
		
		public function GroupMemberActivityDay()
		{
		}
	}
}