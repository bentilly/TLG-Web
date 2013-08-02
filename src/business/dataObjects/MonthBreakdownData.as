package business.dataObjects
{
	public class MonthBreakdownData
	{
		
		public var _totalDuration:Number = 123; //total number of mins logged this month
		[Bindable] public var _totalDuration_display:String = "123"; //display version of _totalDuration
		public var _avgPerDay:Number = 2.34; //average mins logged per day this month
		[Bindable] public var _avgPerDay_display:String = "2:34"; //display version of _avgPerDay
		
		public function MonthBreakdownData()
		{
		}
	}
}