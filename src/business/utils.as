package business
{
	import mx.collections.ArrayCollection;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	

	public class utils
	{
		/*** IMPORT ***/
		[Bindable] public var myGroups_collection:ArrayCollection;
		[Bindable] public var myActivities_collection:ArrayCollection;
		
		
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
		
		public function compareDates(date1:Date, date2:Date):Boolean{ //returns true if the dates are the same
			if( getSortNumberFromDate(date1) == getSortNumberFromDate(date2) ){
				return true;
			}
			
			return false;	
		}
		
		public function compareMonths(date1:Date, date2:Date):Boolean{ //returns true if the months are the same
			if( getMonthSortNumberFromDate(date1) == getMonthSortNumberFromDate(date2) ){
				return true;
			}
			
			return false;
		}
		
		public function sortArrayCollection(ar:ArrayCollection, fieldName:String, isNumeric:Boolean=false, order:String='ASC'):void 
		{
			var dataSortField:SortField = new SortField();
			dataSortField.name = fieldName;
			dataSortField.numeric = isNumeric;
			if (order.toUpperCase() == "DESC") { 
				dataSortField.descending = true; 
			}
			
			var numericDataSort:Sort = new Sort();
			numericDataSort.fields = [dataSortField];
			ar.sort = numericDataSort;
			ar.refresh();
		}
		public function sortGroupMemberActivityDayCollection(ar:ArrayCollection):void{			
			var groupSort:SortField = new SortField();
			groupSort.name = '_groupKey';
			
			var memberSort:SortField = new SortField();
			memberSort.name = '_email';
			
			var activitySort:SortField = new SortField();
			activitySort.name = '_activityKey';
			
			var dateSort:SortField = new SortField();
			dateSort.name = '_date';
			dateSort.numeric = true;
			
			var dataSort:Sort = new Sort();
			dataSort.fields = [groupSort, memberSort, activitySort, dateSort];
			ar.sort = dataSort;
			ar.refresh();
		}
		
		public function formatDurationForDisplay(duration:Number):String{
			var totalString:String = String(Math.floor(duration/60));
			totalString = totalString + ':';
			var mins:String = String(duration - (Math.floor(duration/60) * 60));
			if(mins.length < 2){
				mins = '0' + mins;
			}
			totalString = totalString + mins;
			return totalString;
		}
		
		
		
		
		
		
		
		
		
		
		
	}
}