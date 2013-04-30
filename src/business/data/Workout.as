package business.data
{
	public class Workout
	{
		public var _key:String;
		public var _date:Date;
		[Bindable] public var _duration:Number;
		[Bindable] public var _hrs:String;
		[Bindable] public var _mins:String;
		[Bindable] public var _comment:String;
		public var _activities:Array; //Array of Activity objects
		
		
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
			_activities = activities;
		}
		
		private function setHrsMins(duration:Number):void{
			_hrs = String(  Math.floor(_duration/60)  );
			_mins = String(  _duration - ( Math.floor(_duration/60)*60 )  );
		}
	}
}