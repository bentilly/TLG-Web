package business
{
	public class utils
	{
		public function utils()
		{
		}
		
		public function getSortNumberFromDate(d:Date):Number{
			//turns a Date object into a number that can be sorted or compared, eg 20130423
			
			var yearString:String = String(d.fullYear);
			var monthString:String = String(d.month)
			if(monthString.length < 2){
				monthString = "0" + monthString;
			}
			var dateString:String = String(d.date)
			if(dateString.length < 2){
				dateString = "0" + dateString;
			}
			
			var dString:String = yearString + monthString + dateString;
			return Number(dString);
		}
		
		public function getMonthSortNumberFromDate(d:Date):Number{
			//turns a Date object into a number that can be sorted or compared - by Month, eg 201304
			var yearString:String = String(d.fullYear);
			var monthString:String = String(d.month)
			if(monthString.length < 2){
				monthString = "0" + monthString;
			}
			var dString:String = yearString + monthString;
			return Number(dString);
		}
		
	}
}