package events{
	import flash.events.Event;
	
	public class UIEvent extends Event{

		public static const USER_LOGGED_IN:String = "userLoggedIn_event";
		public static const GOT_GROUPS:String = "gotGroups_event";
		public static const GOT_MY_ACTIVITES:String = "gotMyActivities_event";
		public static const WORKOUT_ADDED:String = "workoutAdded_event";
		
		public static const GO_HOME:String = "goHome_event";
		public static const GO_MYWORKOUTS:String = "goMyWorkouts_event";
		
		
		public function UIEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}
	}
}