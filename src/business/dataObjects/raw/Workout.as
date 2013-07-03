package business.dataObjects.raw
{
	import mx.collections.ArrayCollection;
	
	import business.utils;

	public class Workout
	{
		public var _key:String;
		[Bindable] public var _date:Date;
		[Bindable] public var _duration:Number;
		[Bindable] public var _hrs:String;
		[Bindable] public var _mins:String;
		[Bindable] public var _comment:String;
		[Bindable] public var _activities_collection:ArrayCollection; //Array of Activity objects
		
		//Sorting the timeline
		public var firstActivityName:String;
		
		//Grouping like dates
		[Bindable] public var _first:Boolean = false;
		[Bindable] public var _last:int = 0;
		
		
		private var utils:business.utils = new business.utils();
		
		
		
		public function Workout(o:Object, activities:Array)
		{
			buildWorkout(o, activities);
		}
		public function updateWorkout(o:Object, activities:Array):void{
			buildWorkout(o, activities);
		}
		
		
		private function buildWorkout(o:Object, activities:Array):void{
			_key = o.key;
			var dateBits:Array = o.date.split('-');
			_date = new Date(dateBits[0], dateBits[1]-1, dateBits[2]);
			_duration = Number(o.duration);
			setHrsMins(_duration);
			_comment = o.comment;
			_activities_collection = new ArrayCollection(activities);
			//sort field for timeline
			if(_activities_collection.length > 1){ // workout can have no activity
				firstActivityName = _activities_collection[0]._name;
			}
		}
		
		private function setHrsMins(duration:Number):void{
			_hrs = String(  Math.floor(_duration/60)  );
			_mins = String(  _duration - ( Math.floor(_duration/60)*60 )  );
		}
		
	}
}