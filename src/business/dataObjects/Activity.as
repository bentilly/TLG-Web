package business.dataObjects
{
	import view.widgets.activityTag;

	public class Activity
	{
		
		public var _key:String;
		[Bindable] public var _name:String;
		[Bindable] public var _colour:Number;
		
		//UI components
		private var addBarActivityTag:activityTag;
		private var editWorkoutActivityTag:activityTag;
		private var workoutListItemActivityTag:activityTag;
		
		
		public function Activity(o:Object)
		{
			_key = o.key;
			_name = o.name;
			_colour = Number('0x'+o.colour);
			
			build_addBarActivityTag();
			build_editWorkoutActivityTag();
			build_workoutListItemActivityTag();
		}
		
		
		/* ------- UI components -------- */
		//Add bar
		private function build_addBarActivityTag():void{
			addBarActivityTag = new activityTag();
			addBarActivityTag.activity = this;
		}
		public function get_addBarActivityTag():activityTag{
			return addBarActivityTag;
		}
		//Edit Workout Popup
		private function build_editWorkoutActivityTag():void{
			editWorkoutActivityTag = new activityTag();
			editWorkoutActivityTag.activity = this;
		}
		public function get_editWorkoutActivityTag():activityTag{
			return editWorkoutActivityTag;
		}
		//Workout list items
		private function build_workoutListItemActivityTag():void{
			workoutListItemActivityTag = new activityTag();
			workoutListItemActivityTag.activity = this;
		}
		public function get_workoutListItemActivityTag():activityTag{
			return workoutListItemActivityTag;
		}
	}
}