package business.dataObjects.raw
{
	import mx.collections.ArrayCollection;

	public class WorkoutMonth
	{
		
		[Bindable] public var _date:Date; //the date of the first of this month
		[Bindable] public var _workoutDays:ArrayCollection; //array of WorkoutDay objects for this month
		
		public function WorkoutMonth()
		{
			_workoutDays = new ArrayCollection([]);
		}		
		
		
	}
}