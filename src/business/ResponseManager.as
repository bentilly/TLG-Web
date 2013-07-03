package business{
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IViewCursor;
	import mx.controls.Alert;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	import business.dataObjects.ActivitySummary;
	import business.dataObjects.GroupMemberWorkoutDay;
	import business.dataObjects.GroupMember_Data;
	import business.dataObjects.Group_Data;
	import business.dataObjects.WorkoutDay;
	import business.dataObjects.WorkoutMonth;
	import business.dataObjects.raw.Activity;
	import business.dataObjects.raw.GroupMember;
	import business.dataObjects.raw.TLGGroup;
	import business.dataObjects.raw.TLGUser;
	import business.dataObjects.raw.Workout;
	import business.dataObjects.raw.WorkoutDay2;
	import business.dataObjects.raw.WorkoutMonth2;
	
	import events.RequestEvent;
	import events.UIEvent;

	
	
	
	public class ResponseManager{
		
		/*** INTERNAL ***/
		private var dispatcher:IEventDispatcher;
		private var utils:business.utils = new business.utils();
		
		
		/*** EXPORT ***/
		//Master collections of DB objects
		private var user_collection:ArrayCollection;
		private var group_collection:ArrayCollection;
		private var groupMember_collection:ArrayCollection;
		private var activity_collection:ArrayCollection;
		private var workout_collection:ArrayCollection;
		private var groupMemberActivityDay_collection:ArrayCollection;
		//Collections specifically used for display
		[Bindable] public var workoutDay_collection:ArrayCollection; //a collection of WorkoutDay2
		[Bindable] public var workoutMonth_collection:ArrayCollection; //a collection of WorkoutMonth2
		
		
		[Bindable] public var URLPrefix:String;
		[Bindable] public var token:String;//token is used to authenticate this user on every request. Use token.creatToken to log in and get a new token.
		[Bindable] public var userName:String; //returned when someone logs in
		[Bindable] public var userEmail:String;
		[Bindable] public var myGroups_collection:ArrayCollection; //array of TlgGroup objects - groups I am a member or admin of
		[Bindable] public var myActivities:Array; //array of personal activities
		[Bindable] public var myActivities_collection:ArrayCollection; //array of personal activities
		[Bindable] public var currentGroup:Group_Data = null; //the current group (if looking at a group).
		
		
		public function ResponseManager(dispatcher:IEventDispatcher){
			this.dispatcher = dispatcher; //creates a dispatcher so this class can send events. Initiated in TLGEventMap.mxml
			resetDataStorage();
			
			trace("ResponseManager Initialised");
		}
		
		private function resetDataStorage():void{
			//create empty arraycollections for master data
			user_collection = new ArrayCollection();
			group_collection = new ArrayCollection();
			groupMember_collection = new ArrayCollection();
			activity_collection = new ArrayCollection();
			workout_collection = new ArrayCollection();
			groupMemberActivityDay_collection = new ArrayCollection();
			
			//set the sort order for workouts
			utils.sortArrayCollection(workout_collection, '_date', true, "DESC");
		}
		
		public function handleResponse(event:RequestEvent, resultObject:Object):void{
			var uie:UIEvent;
			
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
						
						token_createToken_handler(result);
						break;
				//USER
					case "user.signup": //on successful signup a login token is returned - log them in
						token = result.token;
						userName = result.name;
						userEmail = request.email;
						token_createToken_handler(result);
						break;
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
						//turn off spinner
						uie = new UIEvent(UIEvent.SPINNER_OFF);
						dispatcher.dispatchEvent(uie);
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
				//turn off spinner
				uie = new UIEvent(UIEvent.SPINNER_OFF);
				dispatcher.dispatchEvent(uie);
			}
		}
		
		public function handleFault(event:RequestEvent, fault:Object, resultObject:Object):void{
			Alert.show(String(fault), "Error");
			
			//Get Operation
			var request:Object = JSON.parse(String(event.requestJson));
			var operation:String = request.operation;
			if(operation == "token.createToken"){
				token_createToken_fail_handler(); //unlock the login UI on RPC fail
			}
			
			//turm off spinner
			var uie:UIEvent = new UIEvent(UIEvent.SPINNER_OFF);
			dispatcher.dispatchEvent(uie);
			
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
				//sets leaderboard
				var uie:UIEvent = new UIEvent(UIEvent.GROUP_READY);
				dispatcher.dispatchEvent(uie);
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
		private function token_createToken_handler(result:Object):void{
			//master data
			var me:TLGUser = new TLGUser();
			me._name = result.name;
			me._email = result.email;
			user_collection.addItem(me);
			//END master data
			
			//trigger further action
			var uie:UIEvent = new UIEvent(UIEvent.USER_LOGGED_IN);
			dispatcher.dispatchEvent(uie);
			
			//Wait until all data loaded before turning off spinner: getAllWorkouts
		}
		private function token_createToken_fail_handler():void{
			var uie:UIEvent = new UIEvent(UIEvent.LOGIN_FAIL);
			dispatcher.dispatchEvent(uie);
			
			//turn off spinner
			uie = new UIEvent(UIEvent.SPINNER_OFF);
			dispatcher.dispatchEvent(uie);
		}
		
//-----USER-----//
		private function user_getGroups_handler(groups:Array):void{
			//master data storage
			for each(var g:Object in groups){
				var tlggroup:TLGGroup = new TLGGroup();
				tlggroup._key = g.key;
				tlggroup._name = g.name;
				if(g.admin == 'true'){
					tlggroup._admin = true;
				}
				group_collection.addItem(tlggroup);
			}
			//END master data
			
			//in use
			myGroups_collection = new ArrayCollection();
			for each(var o:Object in groups){
				var group:Group_Data = new Group_Data(o.name, o.key);
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
			//master data storage
			//my activities
			for each(var ao:Object in result.activities){
				var act:Activity = new Activity();
				act._key = ao.key;
				act._name = ao.name;
				act._colour = Number('0x'+ao.colour);
				act._editable = true;
				activity_collection.addItem(act);
			}
			
			//group activities
			for each(var go:Object in result.groupActivities){
				var tlggroup:TLGGroup = getGroupObjectByKey(go.key);
				for each(var gao:Object in go.activities){
					var gact:Activity = new Activity();
					gact._key = gao.key;
					gact._name = gao.name;
					gact._colour = Number('0x'+gao.colour);
					gact._group = tlggroup;
					activity_collection.addItem(gact);
				}
			}
			//END master data
			
			//My personal activities
			var activities:Array = result.activities;
			myActivities = new Array();
			for each(var o:Object in activities){
				var a:Activity = new Activity();
				a._key = o.key;
				a._name = o.name;
				a._colour = Number('0x'+o.colour);
				a._group = tlggroup;
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
				var tlgGroup:Group_Data = getGroupByKey(g.key);
				if(tlgGroup){
					for each(var ga:Object in g.activities){
						var activity:Activity = new Activity();
						activity._editable = tlgGroup._admin;
						activity._groupData = tlgGroup;
						activity._key = ga.key;
						activity._name = ga.name;
						activity._colour = Number('0x'+ga.colour);
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
		
/** GET ALL WORKOUTS **/
		private function user_getAllWorkouts_handler(workouts:Array):void{		
			for each(var o:Object in workouts){
				//Master data - an array to store Activities
				var mdActivities:Array = new Array();
				//store activities
				for each(var i:Object in o.activities){
					mdActivities.push( getActivityObjectByKey(i.key) );
				}
				//Master data - create and add workout
				workout_collection.addItem( new Workout(o, mdActivities) );
				
			}
			build_workoutDay_collection(); //update my workouts lists for display
			
			//Changes screen in UI
			var uie:UIEvent = new UIEvent(UIEvent.GOT_ALL_WORKOUTS);
			dispatcher.dispatchEvent(uie);
			
			//turn off spinner
			uie = new UIEvent(UIEvent.SPINNER_OFF);
			dispatcher.dispatchEvent(uie);
		}
		
		
		
//-----WORKOUT-----//
/** ADD WORKOUT **/
		private function workout_addWorkout_handler(result:Object, request:Object):void{
			var uie:UIEvent;
			//Master data - an array to store Activities
			var mdActivities:Array = new Array();
			if(result.activityKey){
				var o:Object = {'name':result.activityName, 'key':result.activityKey, 'colour':result.activityColour};
				//Add to master data
				var act:Activity = new Activity();
				act._key = o.key;
				act._name = o.name;
				act._colour = Number('0x'+o.colour);
				act._editable = true;
				activity_collection.addItem(act);
				mdActivities.push( act );
			}
			//all other activities
			for each(var ak:String in request.activities){
				act = getActivityObjectByKey(ak);
				if(act){ mdActivities.push( act ); };
			}
			
			var wo:Object = new Object();
			wo.key = result.key;
			wo.date = request.date;
			wo.duration = request.duration;
			wo.comment = request.comment;
			
			
			//Master data - create and add workout
			var w:Workout = new Workout(wo, mdActivities);
			workout_collection.addItem( w );
			build_workoutDay_collection(); //update my workouts lists
			
			uie = new UIEvent(UIEvent.WORKOUT_ADDED); //updates the calendar. Could do this better
			uie.workout = w;
			dispatcher.dispatchEvent(uie);
			
			
		}
		
		private function workout_updateWorkout_handler(result:Object, request:Object):void{
			var o:Object;
			
			//Workout Object
			var wo:Object = new Object();
			wo.key = result.key;
			wo.date = request.date;
			wo.duration = request.duration;
			wo.comment = request.comment;
			
			
			//Master data update
			var mdActivities:Array = new Array();
			//Delete workout
			deleteWorkoutObjectByKey(request.key);
			//Activities
			if(result.activityKey){ //new personal activity
				o = {'name':result.activityName, 'key':result.activityKey, 'colour':result.activityColour};
				var act:Activity = new Activity();
				act._key = o.key;
				act._name = o.name;
				act._colour = Number('0x'+o.colour);
				activity_collection.addItem(act);
				mdActivities.push( act );
			}
			//Group activities
			for each(var ga:String in request.activities){
				var activityObject:Activity = getActivityObjectByKey(ga);
				if(activityObject){
					activity_collection.addItem(activityObject);
				}
			}
			workout_collection.addItem( new Workout(wo, mdActivities) );
			//sortAndFilterWorkouts();
			//END Master data update
			
			
			var uie:UIEvent;
			var activities:Array = [];
			var activity:Activity;
			
			//Activities
			var newActivity:Activity;
			//New Activity
			if(result.activityKey){
				o = {'name':result.activityName, 'key':result.activityKey, 'colour':result.activityColour};
				newActivity = new Activity();
				newActivity._key = o.key;
				newActivity._name = o.name;
				newActivity._colour = Number('0x'+o.colour);
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
			
			var workoutDateChanged:Boolean = false;
			var workoutToShift:Workout;
			
			//find and remove local workout
			//TODO: This is shit - do it again
			/*for each(var wm:WorkoutMonth in workoutDaysByMonth_collection){
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
			}*/
			
			//tell calendar chart to move a workout block
			if(workoutDateChanged){
				uie = new UIEvent(UIEvent.WORKOUT_DATE_CHANGED);
				uie.workout = workoutToShift;
				dispatcher.dispatchEvent(uie);
			}
			
			
			//UI muast be on MyWorkouts page. Set groups to _loaded = false so they reload when user goes back. Cheating but easy.
			for each(var tlgGroup:Group_Data in myGroups_collection){
				tlgGroup._loaded = false;
				//dump all data
				tlgGroup._members_collection.removeAll();
			}
			
		}
		
		private function workout_deleteWorkout_handler(result:Object, request:Object):void{
			//Master data
			deleteWorkoutObjectByKey(request.key);
			
			//delete workout from my_workouts
			/*for each(var wm:WorkoutMonth in workoutDaysByMonth_collection){
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
							for each(var tlgGroup:Group_Data in myGroups_collection){
								tlgGroup._loaded = false;
								//dump all data
								tlgGroup._members_collection.removeAll();
							}
							
							trace('Workout deleted');
						}
						wCount++;
					}
				}
			}*/
			
		}
		
		
//-----GROUP-----//

		private function group_getMemberWorkouts_handler(result:Object, request:Object):void{
			var m:Object;
			
			//Master data
			var groupObject:TLGGroup = getGroupObjectByKey(request.group);
			if(!groupObject._loaded){
				for each(m in result.members){
					//Add user
					var tlguser:TLGUser = new TLGUser();
					tlguser._name = m.name;
					tlguser._email = m.email;
					user_collection.addItem(tlguser);
					//Add group member
					var groupMember:GroupMember = new GroupMember();
					groupMember._user = tlguser;
					groupMember._group = groupObject;
					groupMember_collection.addItem(groupMember);
				}
				group._loaded = true;
			}
			//END Master data
			
			var group:Group_Data = getGroupByKey(request.group);
			if(!group._loaded){
				for each(m in result.members){
					group.addMember(m);
				}
				group._loaded = true;
			}
			utils.sortArrayCollection(group._members_collection, '_totalDuration', true, 'DESC');
			//sets leaderboard
			var uie:UIEvent = new UIEvent(UIEvent.GROUP_READY);
			dispatcher.dispatchEvent(uie);
		}
		
		
		
//-----ACTIVITY-----//
		private function activity_addActivity_handler(result:Object, request:Object):void{
			if(request.group){
				//Master data
				var groupObject:TLGGroup = getGroupObjectByKey(request.group);
				var act:Activity = new Activity();
				act._key = result.key;
				act._name = request.name;
				act._colour = Number('0x'+request.colour);
				activity_collection.addItem(act);
				//END Master data
				
				//group activity added
				var tlgGroup:Group_Data = getGroupByKey(request.group);
				//New Activity
				var o:Object = {'name':request.name, 'key':result.key, 'colour':request.colour};
				var newActivity:Activity = new Activity();
				newActivity._key = o.key;
				newActivity._name = o.name;
				newActivity._colour = Number('0x'+o.colour);
				newActivity._editable = tlgGroup._admin;
				newActivity._groupData = tlgGroup;
				tlgGroup.addActivity(newActivity);
				utils.sortArrayCollection(tlgGroup._activities_collection, '_name');
			}
			
		}
		private function activity_updateActivity_handler(result:Object, request:Object):void{
			//Master data
			var act:Activity = getActivityObjectByKey(request.key);
			if(act){
				act._colour = Number('0x'+request.colour);
				act._name = request.name;
			}
			//END Master data
			
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
		private function addWorkoutToCollection(w:Workout):void{
			var newDay:WorkoutDay;
			var newMonth:WorkoutMonth;
			
			var monthExists:Boolean = false;
			/*for each(var wm:WorkoutMonth in workoutDaysByMonth_collection){
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
			}*/
			
			/*if(!monthExists){
				//make month and day
				//make day
				newDay = new WorkoutDay(new Date(w._date.fullYear, w._date.month, w._date.date) , [w]);
				//make month
				newMonth = new WorkoutMonth(new Date(w._date.fullYear, w._date.month, w._date.date) , [newDay]);
				workoutDaysByMonth_collection.addItem(newMonth);
			}*/
		}
		
		private function addWorkoutToGroups(workout:Workout):Boolean{ //returns true if this workout was added to a group
			
			trace('-------- addWorkoutToGroups');
			
			//might need these later
			var newActivitySummary:ActivitySummary;
			var newWorkoutDay:GroupMemberWorkoutDay;
			var addedToGroup:Boolean = false;
			
			
			//for all the groups
			for each(var tlgGroup:Group_Data in myGroups_collection){
				trace('check group '+tlgGroup._name);
				//is the group loaded and in need of update
				if(tlgGroup._loaded){
					for each(var member:GroupMember_Data in tlgGroup._members_collection){
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
		
		
/** GETTERS **/
		
		public function getGroupByKey(key:String):Group_Data{
			for each(var group:Group_Data in myGroups_collection){
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
			for each(var tlgGroup:Group_Data in myGroups_collection){
				for each(var groupActivity:Activity in tlgGroup._activities_collection){
					if(groupActivity._key == key){
						return groupActivity;
					}
				}
			}
			return null;
		}
		private function getActivityGroupByKey(key:String):Group_Data{
			for each(var tlgGroup:Group_Data in myGroups_collection){
				for each(var groupActivity:Activity in tlgGroup._activities_collection){
					if(groupActivity._key == key){
						return tlgGroup;
					}
				}
			}
			return null;
		}
		private function getGroupMemberWorkoutDay_byGroupMemberAndDate(member:GroupMember_Data, date:Date):GroupMemberWorkoutDay{
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
		
		
/** MASTER DATA tools **/
		//Get TLGGroup from group_collection
		public function getGroupObjectByKey(key:String):TLGGroup{
			for each(var group:TLGGroup in group_collection){
				if(group._key == key){
					return group;
				}
			}
			return null;
		}
		public function getActivityObjectByKey(key:String):Activity{
			for each(var activity:Activity in activity_collection){
				if(activity._key == key){
					return activity;
				}
			}
			return null;
		}
		public function deleteWorkoutObjectByKey(key:String):Boolean{
			var count:int = 0;
			for each(var wo:Workout in workout_collection){
				if(wo._key == key){
					workout_collection.removeItemAt(count);
					return true;
				}
				count++;
			}
			return false;
		}
		
		private function build_workoutDay_collection():void{		
			//empty collection
			workoutDay_collection = new ArrayCollection([]);
			//work through workout_collection
			var cursor:IViewCursor = workout_collection.createCursor();
			var wd:WorkoutDay2 = new WorkoutDay2();
			//set the sorting for the workouts
			var w:Workout = cursor.current as Workout;
			wd._date = new Date(w._date.fullYear, w._date.month, w._date.date);
			wd._workouts.addItem(w);
			cursor.moveNext();
			while (! cursor.afterLast) {
				w = cursor.current as Workout;
				if(w._date.time == wd._date.time){
					wd._workouts.addItem(w);
				}else{
					workoutDay_collection.addItem(wd);
					utils.sortArrayCollection(wd._workouts, 'firstActivityName');
					wd = new WorkoutDay2();
					wd._date = new Date(w._date.fullYear, w._date.month, w._date.date);
					wd._workouts.addItem(w);
				}
				cursor.moveNext();
			}
			//add last day
			workoutDay_collection.addItem(wd);
			utils.sortArrayCollection(wd._workouts, 'firstActivityName');
			
			
			utils.sortArrayCollection(workoutDay_collection, '_date', true, "DESC");
			
			build_workoutMonth_collection();
			
			workoutDay_collection.filterFunction = filterFunction_WorkoutByMonth;
			workoutDay_collection.refresh();
		}
		
		private function build_workoutMonth_collection():void{
			//empty collection
			workoutMonth_collection = new ArrayCollection([]);
			//work through workoutDay_collection
			var cursor:IViewCursor = workoutDay_collection.createCursor();
			var wm:WorkoutMonth2 = new WorkoutMonth2();
			var wd:WorkoutDay2 = cursor.current as WorkoutDay2;
			wm._date = new Date(wd._date.fullYear, wd._date.month);
			wm._workoutDays.addItem(wd);
			cursor.moveNext();
			
			while (! cursor.afterLast) {
				wd = cursor.current as WorkoutDay2;
				if( utils.compareMonths(wd._date, wm._date) ){
					wm._workoutDays.addItem(wd);
				}else{
					workoutMonth_collection.addItem(wm);
					wm = new WorkoutMonth2();
					wm._date = new Date(wd._date.fullYear, wd._date.month);
					wm._workoutDays.addItem(wd);
				}
				cursor.moveNext();
			}
			//add last
			workoutMonth_collection.addItem(wm);
			//sort
			utils.sortArrayCollection(workoutMonth_collection, '_date', true, "DESC");
			workoutMonth_collection.refresh();
		}
		
		
		
/** Filtering and sorting **/
		//Filter workout_collection by month
		private var nowDate:Date = new Date();
		[Bindable] private var selectedMonth:Date = new Date(nowDate.fullYear, nowDate.month);
		
		public function setWorkoutMonth(event:UIEvent):void{
			selectedMonth = event.date;
			workoutDay_collection.refresh();
		}
		
		private function sortWorkouts():void{
			var dateSort:SortField = new SortField();
			dateSort.name = '_date';
			dateSort.numeric = true;
			dateSort.descending = true;
			
			var activitySort:SortField = new SortField();
			activitySort.name = 'firstActivityName';
			activitySort.numeric = false;
			activitySort.descending = false;
			
			var workoutSort:Sort = new Sort();
			workoutSort.fields = [dateSort, activitySort];
			workout_collection.sort = workoutSort;
			workout_collection.refresh();
			
		}
		
		//Filter functions
		private function filterFunction_WorkoutByMonth(w:WorkoutDay2):Boolean{
			if(w._date.time >= selectedMonth.time){
				var endDate:Date = new Date(selectedMonth.fullYear, selectedMonth.month+1);
				if(w._date.time < endDate.time){
					return true;
				}
			}
			return false;
		}
	}
}










