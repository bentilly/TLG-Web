package business.dataObjects
{
	public class ActivitySummary
	{
		
		[Bindable] public var _activity:Activity;
		[Bindable] public var _duration:Number;
		[Bindable] public var _activity_name:String; //used for sorting
		
		public function ActivitySummary()
		{
		}
	}
}