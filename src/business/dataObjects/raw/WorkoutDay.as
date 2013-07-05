package business.dataObjects.raw
{
	import mx.collections.ArrayCollection;

	public class WorkoutDay
	{
		
		[Bindable] public var _date:Date;
		[Bindable] public var _workouts:ArrayCollection;
		
		public function WorkoutDay()
		{
			_workouts = new ArrayCollection([]);
		}
		
		
		
	}
}