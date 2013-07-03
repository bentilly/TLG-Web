package business.dataObjects
{
	import mx.collections.ArrayCollection;
	import business.dataObjects.raw.Workout;

	public class WorkoutDay
	{
		
		[Bindable] public var _date:Date;
		[Bindable] public var _workouts:Array;
		[Bindable] public var _workouts_collection:ArrayCollection; //Collection of Workout objects
		
		public function WorkoutDay(date:Date, workouts:Array)
		{
			_date = date;
			_workouts = workouts
			_workouts_collection = new ArrayCollection(_workouts);
		}
		
		public function addWorkout(workout:Workout):void{
			_workouts_collection.addItem(workout);
		}
		
		
		
	}
}