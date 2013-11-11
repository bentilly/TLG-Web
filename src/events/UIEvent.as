package events{
	import flash.events.Event;
	

	import business.dataObjects.raw.TLGGroup;
	import business.dataObjects.raw.Workout;
	
	public class UIEvent extends Event{

		public static const USER_LOGGED_IN:String = "userLoggedIn_event";
		public static const GOT_GROUPS:String = "gotGroups_event";
		public static const GOT_MY_ACTIVITES:String = "gotMyActivities_event";
		
		//Activity
		public static const ACTIVITIES_UPDATED:String = "activitiesUpdated_event";
		public static const ACTIVITY_UPDATED:String = "activityUpdated_event";
		public static const ACTIVITY_UPDATE_FAIL:String = "activityUpdateFail_event";
		
		//Workout
		public static const WORKOUT_ADDED:String = "workoutAdded_event";
		public static const WORKOUT_DATE_CHANGED:String = "workoutDateChanged_event";
		public static const WORKOUT_DELETED:String = "workoutDeleted_event";
		public static const GOT_ALL_WORKOUTS:String = "gotAllWorkouts_event";
		public static const BUILD_MYWORKOUTS:String = "buildMyWorkouts_event";
		public static const SET_WORKOUT_MONTH:String = "setWorkoutMonth_event";
		
		//Group
		public static const GROUP_ADDED:String = "groupAdded_event";
		
		//Interaction
		public static const GO_HOME:String = "goHome_event";
		public static const GO_MYWORKOUTS:String = "goMyWorkouts_event";
		public static const GO_GROUP:String = "goGroup_event";
		public static const GROUP_READY:String = "groupReady_event";
		public static const CLEAR_GROUP:String = "clearGroup_event";
		
		public static const UPDATE_LEADERBOARD_RANGE:String = "updateLeaderboardRange_event"; 
		
		public static const LOGIN_FAIL:String = "loginFail_event";
		public static const LOGOUT:String = "logout_event";
		
		public static const SPINNER_ON:String = "spinnerOn_event";
		public static const SPINNER_OFF:String = "spinnerOff_event";
		
		
		public var workout:Workout;
		public var tlgGroup:TLGGroup;
		public var date:Date;
		
		//leaderboard
		public var lbStartDate:Date;
		public var lbEndDate:Date; 
		
		public function UIEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}
	}
}