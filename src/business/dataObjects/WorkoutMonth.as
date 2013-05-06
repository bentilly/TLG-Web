package business.dataObjects
{
	import mx.collections.ArrayCollection;

	public class WorkoutMonth
	{
		
		[Bindable] public var _date:Date; //the date of the first of this month
		[Bindable] public var _workoutDays:Array; //array of WorkoutDay objects for this month
		[Bindable] public var _workoutDays_collection:ArrayCollection; //array of WorkoutDay objects for this month
		
		public function WorkoutMonth(date:Date, workoutDays:Array)
		{
			_date = date;
			_workoutDays = workoutDays;
			_workoutDays_collection = new ArrayCollection(_workoutDays);
		}
		
		public function addWorkoutDay(workoutDay:WorkoutDay):void{
			_workoutDays_collection.addItem(workoutDay);
		}
		
		
		
	}
}