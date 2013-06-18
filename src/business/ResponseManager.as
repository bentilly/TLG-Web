package business{
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	import business.dataObjects.Activity;
	import business.dataObjects.ActivitySummary;
	import business.dataObjects.GroupMember;
	import business.dataObjects.GroupMemberWorkoutDay;
	import business.dataObjects.TlgGroup;
	import business.dataObjects.Workout;
	import business.dataObjects.WorkoutDay;
	import business.dataObjects.WorkoutMonth;
	
	import events.RequestEvent;
	import events.UIEvent;

	
	
	
	public class ResponseManager{
		
		/*** INTERNAL ***/
		private var dispatcher:IEventDispatcher;
		private var utils:business.utils = new business.utils();
		
		
		/*** EXPORT ***/
		
		[Bindable] public var token:String;//token is used to authenticate this user on every request. Use token.creatToken to log in and get a new token.
		[Bindable] public var userName:String; //returned when someone logs in
		[Bindable] public var userEmail:String;
		[Bindable] public var myGroups_collection:ArrayCollection; //array of TlgGroup objects - groups I am a member or admin of
		[Bindable] public var myActivities:Array; //array of personal activities
		[Bindable] public var myActivities_collection:ArrayCollection; //array of personal activities
		[Bindable] public var currentGroup:TlgGroup = null; //the current group (if looking at a group).
		
		//organising workouts
		public var workoutsByDay:Array;  //Array of WorkoutGroup objects containind a days worth of workouts. Organises workouts by day.
		public var workoutDaysByMonth:Array; //Array of WorkoutDay objects containind a days worth of workouts. Organises workouts by day.
		[Bindable] public var workoutDaysByMonth_collection:ArrayCollection; //ArrayCollection for use in UI
		
		public function ResponseManager(dispatcher:IEventDispatcher){
			this.dispatcher = dispatcher; //creates a dispatcher so this class can send events. Initiated in TLGEventMap.mxml
			trace("ResponseManager Initialised");
		}
		
		public function handleResponse(event:RequestEvent, resultObject:Object):void{
			//Get Operation
			var request:Object = JSON.parse(String(event.requestJson));
			var operation:String = request.operation;
			trace("<<........API RESPONSE....... : request = "+operation);
			
			//Parse response JSON
			try{
				var result:Object = JSON.parse(String(resultObject));
				trace("response = "+resultObject);
				
			}catch(e:Error){
				trace(e);
			}
			trace('\n\n');
			
			//Check operation status
			if(result.status == "success"){
				//Handle the response
				switch(operation){
					case "token.createToken": //login
						token = result.token;
						userName = result.name;
						userEmail = request.email;
						token_createToken_handler();
						break;
				//USER
					case "user.getGroups":
						user_getGroups_handler(result.groups);
						break;
					case "user.getAllMyGroups":
						user_getGroups_handler(result.groups);
						break;
					case "user.getActivities":
						user_getActivities_handler(result);
						break;
					case "user.getAllWorkouts":
						user_getAllWorkouts_handler(result.workouts);
						break;
					case "user.resetPassword":
						Alert.show("Email sent to (email address)", "Reset Password");
						break;
				//WORKOUT
					case "workout.addWorkout":
						Alert.show("Workout added","Success");
						workout_addWorkout_handler(result, request);
						break;
					case "workout.updateWorkout":
						workout_updateWorkout_handler(result, request);
						break;
					case "workout.deleteWorkout":
						workout_deleteWorkout_handler(result, request);
						break;
				//GROUP
					case "group.getMemberWorkouts":
						group_getMemberWorkouts_handler(result, request);
						break;
					case "group.addInvite":
						Alert.show("Invite sent to "+request.email, "Invite");
						break;
				//ACTIVITY
					case "activity.addActivity":
						activity_addActivity_handler(result, request);
						break;
					case "activity.updateActivity":
						activity_updateActivity_handler(result, request);
						break;
					default:
						break;
				}
				
				
				
			}else{
				Alert.show(String(result.message), "Something went wrong");
				switch(operation){
					case "activity.updateActivity":
						activity_updateActivity_fail_handler();
						break;
					case "token.createToken": //login fail (wrong password). Re-enable login boxes
						token_createToken_fail_handler();
					default:
						break;
				}
			}
		}
		
		public function handleFault(event:RequestEvent, fault:Object, resultObject:Object):void{
			Alert.show(String(fault), "Error");
			
		}
		
/** -----------------
 * 
 * USER INTERACTION handlers
 * - Usually triggered from TLGEventMap
 * 
 * -----------------**/
		
		public function logout():void{
			//clear all data
			token = '';
			userName = '';
			myGroups_collection.removeAll();
			myActivities = [];
			currentGroup = null;
		}
		
//-----GROUP------//
		public function goGroup(event:UIEvent):void{
			//set current group, update date, request members and workout summaries
			currentGroup = event.tlgGroup;
			
			if(currentGroup._loaded){
				//go to group page - no server call
			}else{
				//get group members and workouts
				var re:RequestEvent = new RequestEvent(RequestEvent.TLG_API_REQUEST);
				var requestObj:Object = new Object();
				requestObj.operation = 'group.getMemberWorkouts';
				requestObj.token = token;
				requestObj.group = currentGroup._key;
				re.requestJson = JSON.stringify(requestObj);
				trace("\n\n>>--------API REQUEST--------- : request = "+requestObj.operation);
				trace(re.requestJson);
				dispatcher.dispatchEvent(re);
			}
		}
		
/** -----------------
 * 
 * DATA Services - response handlers
 * 
 * -----------------**/
		
//-----TOKEN-----//
		private function token_createToken_handler():void{
			var uie:UIEvent = new UIEvent(UIEvent.USER_LOGGED_IN);
			dispatcher.dispatchEvent(uie);
		}
		private function token_createToken_fail_handler():void{
			var uie:UIEvent = new UIEvent(UIEvent.LOGIN_FAIL);
			dispatcher.dispatchEvent(uie);
		}
		
//-----USER-----//
		private function user_getGroups_handler(groups:Array):void{
			myGroups_collection = new ArrayCollection();
			for each(var o:Object in groups){
				var group:TlgGroup = new TlgGroup(o.name, o.key);
				if(o.admin == 'true'){
					group._admin = true;
				}
				if(o.member == 'true'){
					group._member = true;
				}
				myGroups_collection.addItem(group);
			}
			
			var uie:UIEvent = new UIEvent(UIEvent.GOT_GROUPS);
			dispatcher.dispatchEvent(uie);
		}
		
		private function user_getActivities_handler(result:Object):void{
			//My personal activities
			var activities:Array = result.activities;
			myActivities = new Array();
			for each(var o:Object in activities){
				var a:Activity = new Activity(o);
				a._editable = true;
				myActivities.push(a);
			}
			
			//sort
			myActivities.sortOn('_name', Array.CASEINSENSITIVE);
			myActivities_collection = new ArrayCollection(myActivities);
			
			//my groups activities
			var groups:Array = result.groupActivities
			for each(var g:Object in groups){
				//find Group object
				var tlgGroup:TlgGroup = getGroupByKey(g.key);
				if(tlgGroup){
					for each(var ga:Object in g.activities){
						var activity:Activity = new Activity(ga);
						activity._editable = tlgGroup._admin;
						activity._group = tlgGroup;
						tlgGroup.addActivity(activity);
					}
					//sort group activities
					utils.sortArrayCollection(tlgGroup._activities_collection, '_name');
				}
			}
			
			
			
			var uie:UIEvent = new UIEvent(UIEvent.GOT_MY_ACTIVITES);
			dispatcher.dispatchEvent(uie);
			
			//get workout data. TODO: workout how to deal with this when the result is BIG! 
			var re:RequestEvent = new RequestEvent(RequestEvent.TLG_API_REQUEST);
			var requestObj:Object = new Object();
			requestObj.operation = 'user.getAllWorkouts';
			requestObj.token = token;
			re.requestJson = JSON.stringify(requestObj);
			trace("\n\n>>--------API REQUEST--------- : request = "+requestObj.operation);
			trace(re.requestJson);
			dispatcher.dispatchEvent(re);
		}
		
		
		
		private function user_getAllWorkouts_handler(workouts:Array):void{
			//make empty collection
			workoutDaysByMonth_collection = new ArrayCollection([]);
			
			for each(var o:Object in workouts){
				//match activities
				var activities:Array = [];
				for each(var i:Object in o.activities){
					//check for 'my activity'
					for each(var a:Activity in myActivities){
						if(a._key == i.key){
							activities.push(a);
						}
					}
					//check for 'group activities'
					for each(var g:TlgGroup in myGroups_collection){
						for each(var ga:Activity in g._activities_collection){
							if(ga._key == i.key){
								activities.push(ga);
							}
						}
					}
				}
				//create workout
				var w:Workout = new Workout(o, activities);
				
				addWorkoutToCollection(w);

			}
			
			//Changes screen in UI
			var uie:UIEvent = new UIEvent(UIEvent.GOT_ALL_WORKOUTS);
			dispatcher.dispatchEvent(uie);
		}
		
		
		
//-----WORKOUT-----//
		private function workout_addWorkout_handler(result:Object, request:Object):void{
			var uie:UIEvent;
			var activities:Array = [];
			var newActivity:Activity;
			//new personal activity
			if(result.activityKey){
				var o:Object = {'name':result.activityName, 'key':result.activityKey, 'colour':result.activityColour};
				newActivity = new Activity(o);
				newActivity._editable = true;
				//add to collection
				myActivities_collection.addItem(newActivity);
				//sort by _name
				utils.sortArrayCollection(myActivities_collection, '_name');
				//add to workout activities array
				activities.push(newActivity);
			}
			//all other activities
			for each(var ak:String in request.activities){
				var activity:Activity = getActivityByKey(ak);
				if(activity){
					activities.push(activity);
				}
			}
			
			var wo:Object = new Object();
			wo.key = result.key;
			wo.date = request.date;
			wo.duration = request.duration;
			wo.comment = request.comment;
			
			var w:Workout = new Workout(wo, activities);

			//add to workoutDaysByMonth_collection which should update UI
			addWorkoutToCollection(w);
			//Add to Groups to update group UI
			addWorkoutToGroups(w);
			
			uie = new UIEvent(UIEvent.WORKOUT_ADDED);
			uie.workout = w;
			dispatcher.dispatchEvent(uie);
			
			
		}
		
		private function addWorkoutToCollection(w:Workout):void{
			var newDay:WorkoutDay;
			var newMonth:WorkoutMonth;
			
			var monthExists:Boolean = false;
			for each(var wm:WorkoutMonth in workoutDaysByMonth_collection){
				//does WorkoutMonth exist?
				if( utils.compareMonths(wm._date, w._date) ){
					monthExists = true;
					//this month
					var dayExists:Boolean = false;
					for each(var wd:WorkoutDay in wm._workoutDays_collection){
						//does WorkoutDay exist
						if( utils.compareDates(wd._date, w._date) ){
							dayExists = true;
							//add workout to workoutDay
							wd.addWorkout(w);
							utils.sortArrayCollection(wd._workouts_collection, '_date', true, 'DESC');
							break;
						}
					}
					if(!dayExists){
						//make day
						newDay = new WorkoutDay(new Date(w._date.fullYear, w._date.month, w._date.date) , [w]);
						//add to month
						wm.addWorkoutDay(newDay);
						utils.sortArrayCollection(wm._workoutDays_collection, '_date', true, 'DESC');
						break;
					}
				}
			}
			
			if(!monthExists){
				//make month and day
				//make day
				newDay = new WorkoutDay(new Date(w._date.fullYear, w._date.month, w._date.date) , [w]);
				//make month
				newMonth = new WorkoutMonth(new Date(w._date.fullYear, w._date.month, w._date.date) , [newDay]);
				workoutDaysByMonth_collection.addItem(newMonth);
			}
		}
		
		private function addWorkoutToGroups(workout:Workout):Boolean{ //returns true if this workout was added to a group
			
			trace('-------- addWorkoutToGroups');
			
			//might need these later
			var newActivitySummary:ActivitySummary;
			var newWorkoutDay:GroupMemberWorkoutDay;
			var addedToGroup:Boolean = false;
			
			
			//for all the groups
			for each(var tlgGroup:TlgGroup in myGroups_collection){
				trace('check group '+tlgGroup._name);
				//is the group loaded and in need of update
				if(tlgGroup._loaded){
					for each(var member:GroupMember in tlgGroup._members_collection){
						//am I a member of this group
						if(member._currentUser && tlgGroup._member){
							trace('I am a member of this group');
							//is there an activity in this workout for this group
							for each(var workoutActivity:Activity in workout._activities_collection){
								for each(var groupActivity:Activity in tlgGroup._activities_collection){
									if(workoutActivity == groupActivity){
										//activity match - update or add workout
										trace('activity match: '+workoutActivity._name+' : '+groupActivity._name);
										//find GroupMemberWorkoutDay (check dates)
										var foundWorkoutDay:Boolean = false;
										for each(var workoutDay:GroupMemberWorkoutDay in member._workoutDays_collection){
											if(utils.compareDates(workout._date, workoutDay._date)){
												//Workout Day exists
												foundWorkoutDay = true;
												trace('found workoutDay for '+workout._date);
												//Is there an activity summary for this group/member/date/activity
												var foundActSum:Boolean = false;
												for each(var activitySum:ActivitySummary in workoutDay._activity_collection){
													if(activitySum._activity == workoutActivity){
														//Found it! Update duration
														trace('found activitySummary. Updating. END NOW');
														activitySum._duration = activitySum._duration + workout._duration;
														
														//rebuild leaderboard data and return
														member.buildLeaderboardData(member.lbStartDate, member.lbEndDate);
														addedToGroup = true;
														foundActSum = true;
														break;
													}
												}
												if(!foundActSum){
													trace('No activitySummary. Make one. END NOW');
													//No exisiting activity summary. make one
													newActivitySummary = new ActivitySummary();
													newActivitySummary._activity = workoutActivity;
													newActivitySummary._duration = workout._duration;
													newActivitySummary._activity_name = workoutActivity._name;
													workoutDay._activity_collection.addItem(newActivitySummary);
													
													//rebuild leaderboard data and return
													member.buildLeaderboardData(member.lbStartDate, member.lbEndDate);
													addedToGroup = true;
													break;
												}
											}
										}
										if(!foundWorkoutDay){
											trace('No workoutDay for '+workout._date+'. Make one. END NOW');
											//WorkoutDay doesnt exist. Make one
											newWorkoutDay = new GroupMemberWorkoutDay();
											newWorkoutDay._date = new Date(workout._date.fullYear, workout._date.month, workout._date.date);
											//make first activity summary
											newActivitySummary = new ActivitySummary();
											newActivitySummary._activity = workoutActivity;
											newActivitySummary._duration = workout._duration;
											newActivitySummary._activity_name = workoutActivity._name;
											//add activity to day
											newWorkoutDay._activity_collection.addItem(newActivitySummary);
											//add day to group member
											member._workoutDays_collection.addItem(newWorkoutDay);
											
											//rebuild leaderboard data and return
											member.buildLeaderboardData(member.lbStartDate, member.lbEndDate);
											addedToGroup = true;
											break;
										}
									}
									//no group activity in this workout
								}
							}

						}
						//current user is not a member of this group
					}
				}
			}
			return addedToGroup;
		}
		
		
		
		
		private function workout_updateWorkout_handler(result:Object, request:Object):void{
			var uie:UIEvent;
			var activities:Array = [];
			var activity:Activity;
			
			//Activities
			var newActivity:Activity;
			//New Activity
			if(result.activityKey){
				var o:Object = {'name':result.activityName, 'key':result.activityKey, 'colour':result.activityColour};
				newActivity = new Activity(o);
				newActivity._editable = true;
				//add to collection
				myActivities_collection.addItem(newActivity);
				//sort by _name
				utils.sortArrayCollection(myActivities_collection, '_name');
				//add to workout activities array
				activities.push(newActivity);
			}
			
			//Compile all Activities for this workout
			for each(var ak:String in request.activities){
				activity = getActivityByKey(ak);
				if(activity){
					activities.push(activity);
				}
			}
			
			//Workout Object
			var wo:Object = new Object();
			wo.key = result.key;
			wo.date = request.date;
			wo.duration = request.duration;
			wo.comment = request.comment;
			
			var workoutDateChanged:Boolean = false;
			var workoutToShift:Workout;
			
			//find and remove local workout
			//TODO: This is shit - do it again
			for each(var wm:WorkoutMonth in workoutDaysByMonth_collection){
				var dayCount:int = 0;
				for each(var wd:WorkoutDay in wm._workoutDays_collection){
					
					for(var i:int = 0; i<wd._workouts_collection.length; i++){
						if(result.key == wd._workouts_collection.getItemAt(i)._key){
							wd._workouts_collection.getItemAt(i).updateWorkout(wo, activities);
							if( !utils.compareDates(wd._workouts_collection.getItemAt(i)._date, wd._date) ){
								trace('-'+wd._workouts_collection.length);
								
								//some wierd thing where it wont remove the first item. Probably doing something wrong somewhere.
								if(wd._workouts_collection.length > 1 && i == 0){
									workoutToShift = wd._workouts_collection.getItemAt(i) as Workout;
									
									var newWorkoutArray:Array = [];
									for each(var tw:Workout in wd._workouts_collection){
										if(tw._key != wd._workouts_collection.getItemAt(i)._key){
											newWorkoutArray.push(tw);
										}
									}
									wd._workouts = newWorkoutArray;
									wd._workouts_collection = new ArrayCollection(newWorkoutArray);
									
								}else{
									workoutToShift = wd._workouts_collection.removeItemAt(i) as Workout;
								}
								trace('--'+wd._workouts_collection.length);
								addWorkoutToCollection(	workoutToShift );
								workoutDateChanged = true;
								//remove empty days
								if(wd._workouts_collection.length == 0){
									wm._workoutDays_collection.removeItemAt(dayCount);
								}
							}
							break;
						}
					}
					
					dayCount++;
				}
			}
			
			//tell calendar chart to move a workout block
			if(workoutDateChanged){
				uie = new UIEvent(UIEvent.WORKOUT_DATE_CHANGED);
				uie.workout = workoutToShift;
				dispatcher.dispatchEvent(uie);
			}
			
			
			//UI muast be on MyWorkouts page. Set groups to _loaded = false so they reload when user goes back. Cheating but easy.
			for each(var tlgGroup:TlgGroup in myGroups_collection){
				tlgGroup._loaded = false;
				//dump all data
				tlgGroup._members_collection.removeAll();
			}
			
		}
		
		
		private function workout_deleteWorkout_handler(result:Object, request:Object):void{
			//delete workout from my_workouts
			for each(var wm:WorkoutMonth in workoutDaysByMonth_collection){
				for each(var wd:WorkoutDay in wm._workoutDays_collection){
					var wCount:int = 0;
					for each(var w:Workout in wd._workouts_collection){
						if(w._key == request.key){
							
							//removes from my workouts list
							wd._workouts_collection.removeItemAt(wCount);
							
							//removes from timeline
							var uie:UIEvent = new UIEvent(UIEvent.WORKOUT_DELETED);
							uie.workout = w;
							dispatcher.dispatchEvent(uie);
							
							//UI muast be on MyWorkouts page. Set groups to _loaded = false so they reload when user goes back. Cheating but easy.
							for each(var tlgGroup:TlgGroup in myGroups_collection){
								tlgGroup._loaded = false;
								//dump all data
								tlgGroup._members_collection.removeAll();
							}
							
							trace('Workout deleted');
						}
						wCount++;
					}
				}
			}
			
		}
		
		
//-----GROUP-----//

		private function group_getMemberWorkouts_handler(result:Object, request:Object):void{
			var group:TlgGroup = getGroupByKey(request.group);
			if(!group._loaded){
				for each(var m:Object in result.members){
					group.addMember(m);
				}
				group._loaded = true;
			}
			utils.sortArrayCollection(group._members_collection, '_totalDuration', true, 'DESC');
		}
		
		
		
//-----ACTIVITY-----//
		private function activity_addActivity_handler(result:Object, request:Object):void{
			if(request.group){
				//group activity added
				var tlgGroup:TlgGroup = getGroupByKey(request.group);
				//New Activity
				var o:Object = {'name':request.name, 'key':result.key, 'colour':request.colour};
				var newActivity:Activity = new Activity(o);
				newActivity._editable = tlgGroup._admin;
				newActivity._group = tlgGroup;
				tlgGroup.addActivity(newActivity);
				utils.sortArrayCollection(tlgGroup._activities_collection, '_name');
			}
			
		}
		private function activity_updateActivity_handler(result:Object, request:Object):void{
			var activity:Activity = getActivityByKey(request.key);
			if(activity){
				activity._colour = Number('0x'+request.colour);
				activity._name = request.name;
			}
			
		}
		private function activity_updateActivity_fail_handler():void{
			var uie:UIEvent = new UIEvent(UIEvent.ACTIVITY_UPDATE_FAIL);
			dispatcher.dispatchEvent(uie);
		}
		
		
		
/** -----------------
 * 
 * TOOLS
 * - Finders, getters, calculators
 * 
 * -----------------**/
		/*public function getWorkoutByKey(key:String):Workout{
			for each(var wm:WorkoutMonth in workoutDaysByMonth_collection){
				for each(var wd:WorkoutDay in wm._workoutDays_collection){
					for each(var w:Workout in wd._workouts_collection){
						if(w._key == key){
							return w;
						}
					}
				}
			}
			return null;
		}*/
		public function getGroupByKey(key:String):TlgGroup{
			for each(var group:TlgGroup in myGroups_collection){
				if(group._key == key){
					return group;
				}
			}
			return null;
		}
		
		private function getActivityByKey(key:String):Activity{
			for each(var activity:Activity in myActivities_collection){
				if(activity._key == key){
					return activity;
				}
			}
			for each(var tlgGroup:TlgGroup in myGroups_collection){
				for each(var groupActivity:Activity in tlgGroup._activities_collection){
					if(groupActivity._key == key){
						return groupActivity;
					}
				}
			}
			return null;
		}
		private function getActivityGroupByKey(key:String):TlgGroup{
			for each(var tlgGroup:TlgGroup in myGroups_collection){
				for each(var groupActivity:Activity in tlgGroup._activities_collection){
					if(groupActivity._key == key){
						return tlgGroup;
					}
				}
			}
			return null;
		}
		private function getGroupMemberWorkoutDay_byGroupMemberAndDate(member:GroupMember, date:Date):GroupMemberWorkoutDay{
			for each(var day:GroupMemberWorkoutDay in member._workoutDays_collection){
				if( utils.compareDates(day._date, date) ){
					return day;
				}
			}
			return null;
		}
		private function getActivitySummary_byGroupMemberWorkoutDayAndActivity(groupDay:GroupMemberWorkoutDay, activity:Activity):ActivitySummary{
			for each(var actsum:ActivitySummary in groupDay._activity_collection){
				if(actsum._activity == activity){
					return actsum;
				}
			}
			return null;
		}
	}
}










