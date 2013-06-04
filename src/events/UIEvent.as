package events{
	import flash.events.Event;
	
	import business.dataObjects.TlgGroup;
	import business.dataObjects.Workout;
	
	public class UIEvent extends Event{

		public static const USER_LOGGED_IN:String = "userLoggedIn_event";
		public static const GOT_GROUPS:String = "gotGroups_event";
		
		public static const GOT_MY_ACTIVITES:String = "gotMyActivities_event";
		public static const ACTIVITIES_UPDATED:String = "activitiesUpdated_event";
		public static const ACTIVITY_UPDATED:String = "activityUpdated_event";
		public static const ACTIVITY_UPDATE_FAIL:String = "activityUpdateFail_event";
		
		public static const WORKOUT_ADDED:String = "workoutAdded_event";
		public static const WORKOUT_DATE_CHANGED:String = "workoutDateChanged_event";
		public static const GOT_ALL_WORKOUTS:String = "gotAllWorkouts_event";
		public static const BUILD_MYWORKOUTS:String = "buildMyWorkouts_event";
		
		
		public static const GO_HOME:String = "goHome_event";
		public static const GO_MYWORKOUTS:String = "goMyWorkouts_event";
		public static const GO_GROUP:String = "goGroup_event";
		
		public static const LOGIN_FAIL:String = "loginFail_event";
		public static const LOGOUT:String = "logout_event";
		
		
		public var workout:Workout;
		public var tlgGroup:TlgGroup;
		
		
		public function UIEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}
	}
}