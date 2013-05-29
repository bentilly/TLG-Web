package business.dataObjects
{
	import mx.collections.ArrayCollection;

	public class GroupMember
	{
		
		[Bindable] public var _name:String;
		//[Bindable] public var _key:String;
		[Bindable] public var _currentUser:Boolean = false; // set to true if this member is the current logged in user
		[Bindable] public var _group:TlgGroup;
		[Bindable] public var _workoutDays_collection:ArrayCollection; //Collection of GroupMemberWorkoutDay objects
		//leaderboard
		[Bindable] public var _leaderboard_collection:ArrayCollection; //collection of {activity:Activity, duration:Number}. Calculated from _workoutDays_collection and a date range
		[Bindable] public var _totalDuration:Number //the total duration from _leaderboard_collection
		
		
		public function GroupMember(name:String)
		{
			_name = name;
			_workoutDays_collection = new ArrayCollection( [] );
			_leaderboard_collection = new ArrayCollection( [] );
		}
		
		public function buildWorkoutDays(m:Object):void{
			for each(var a:Object in m.activities){
				//find activity
				for each(var activity:Activity in _group._activities_collection){
					if(a.activity == activity._key){
						//store workoutSummaries
						for each(var ws:Object in a.workoutSummaries){
							//the data to save. "On this day, I did X amount of Y"
							var activityDuration:ActivitySummary = new ActivitySummary();
							activityDuration._activity = activity;
							activityDuration._duration = ws.duration;
							//match date - find existing GroupMemberWorkoutDay
							var dayExists:Boolean = false;
							var dateBits:Array = ws.date.split('-');
							var wsDate:Date = new Date(dateBits[0], dateBits[1]-1, dateBits[2]);
							for each(var workoutDay:GroupMemberWorkoutDay in _workoutDays_collection){
								if(wsDate == workoutDay._date){
									dayExists = true;
									workoutDay._activity_collection.addItem(activityDuration);
								}
							}
							if(!dayExists){
								//no exisitng GroupMemberWorkoutDay for this date. make new one
								var wd:GroupMemberWorkoutDay = new GroupMemberWorkoutDay();
								wd._date = wsDate;
								wd._activity_collection = new ArrayCollection( []);
								wd._activity_collection.addItem(activityDuration);
								_workoutDays_collection.addItem(wd);
							}
						}
					}
				}
			}
			
			buildLeaderboardData(new Date(2000), new Date());
			
		}
			
		public function buildLeaderboardData(start:Date, end:Date):void{
			 //clear data
			_leaderboard_collection.removeAll();
			_totalDuration = 0;
			for each(var workoutDay:GroupMemberWorkoutDay in _workoutDays_collection){
				//is workoutDay in the date range
				if(workoutDay._date.time >= start.time &&  workoutDay._date.time < end.time){
					//add all activities from this day to leaderboardData
					for each(var activityDay:ActivitySummary in workoutDay._activity_collection){
						var activityAdded:Boolean = false;
						for each(var activityTotal:ActivitySummary in _leaderboard_collection){
							if(activityDay._activity == activityTotal._activity){
								//activity total already added. updata the total
								activityTotal._duration = activityTotal._duration + activityDay._duration;
								_totalDuration += activityDay._duration;
								activityAdded = true;
							}
						}
						if(!activityAdded){
							//new activity
							var at:ActivitySummary = new ActivitySummary();
							at._duration = activityDay._duration;
							at._activity = activityDay._activity;
							_leaderboard_collection.addItem(at);
							_totalDuration += activityDay._duration;
						}
					}
				}
			}
		}
			
			
			
			
	}
}