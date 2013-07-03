package business.dataObjects.raw
{
	import mx.collections.ArrayCollection;

	public class WorkoutDay2
	{
		
		[Bindable] public var _date:Date;
		[Bindable] public var _workouts:ArrayCollection;
		
		public function WorkoutDay2()
		{
			_workouts = new ArrayCollection([]);
		}
		
		
		
	}
}