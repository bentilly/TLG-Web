package business.dataObjects
{

	public class ActivitySummary
	{
		
		[Bindable] public var _activity:Activity_Data;
		[Bindable] public var _duration:Number;
		[Bindable] public var _activity_name:String; //used for sorting
		
		public function ActivitySummary()
		{
		}
	}
}