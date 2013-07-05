package business{
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IViewCursor;
	import mx.controls.Alert;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	import business.dataObjects.raw.Activity;
	import business.dataObjects.raw.ActivitySummary;
	import business.dataObjects.raw.GroupMember;
	import business.dataObjects.raw.GroupMemberActivityDay;
	import business.dataObjects.raw.LeaderboardItem;
	import business.dataObjects.raw.TLGGroup;
	import business.dataObjects.raw.TLGUser;
	import business.dataObjects.raw.Workout;
	import business.dataObjects.raw.WorkoutDay;
	import business.dataObjects.raw.WorkoutMonth;
	
	import events.RequestEvent;
	import events.UIEvent;

	
	
	
	public class ResponseManager{
		
		/*** INTERNAL ***/
		private var dispatcher:IEventDispatcher;
		private var utils:business.utils = new business.utils();
		
		
		/*** EXPORT ***/
		//Master collections of DB objects
		private var user_collection:ArrayCollection;
		private var activity_collection:ArrayCollection;
		private var workout_collection:ArrayCollection;
		[Bindable] public var group_collection:ArrayCollection;
		private var groupMember_collection:ArrayCollection;
		private var groupMemberActivityDay_collection:ArrayCollection;
		
		//Collections specifically used for display
		[Bindable] public var workoutDay_collection:ArrayCollection; //a collection of WorkoutDay2
		[Bindable] public var workoutMonth_collection:ArrayCollection; //a collection of WorkoutMonth2
		[Bindable] public var myActivities_collection:ArrayCollection; //array of personal activities
		[Bindable] public var leaderboard_collection:ArrayCollection; //used to build group leaderboard.
		
		[Bindable] public var URLPrefix:String;
		[Bindable] public var token:String;//token is used to authenticate this user on every request. Use token.creatToken to log in and get a new token.
		[Bindable] public var userName:String; //returned when someone logs in
		[Bindable] public var userEmail:String;
		[Bindable] public var currentGroup:TLGGroup = null; //the current group (if looking at a group).
		private var nowDate:Date = new Date();
		[Bindable] private var selectedMonth:Date = new Date(nowDate.fullYear, nowDate.month);
		
		
		public function ResponseManager(dispatcher:IEventDispatcher){
			this.dispatcher = dispatcher; //creates a dispatcher so this class can send events. Initiated in TLGEventMap.mxml
			resetDataStorage();
			trace("ResponseManager Initialised");
		}
		
		private function resetDataStorage():void{
			//create empty arraycollections for master data
			user_collection = new ArrayCollection([]);
			activity_collection = new ArrayCollection([]);
			myActivities_collection = new ArrayCollection( [] );
			workout_collection = new ArrayCollection([]);
			group_collection = new ArrayCollection([]);
			groupMember_collection = new ArrayCollection([]);
			groupMemberActivityDay_collection = new ArrayCollection([]);
			leaderboard_collection = new ArrayCollection( [] );
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
			userEmail = '';
			currentGroup = null;
			
			//clear collections
			user_collection.removeAll();
			activity_collection.removeAll();
			myActivities_collection.removeAll();
			workout_collection.removeAll();
			group_collection.removeAll();
			groupMember_collection.removeAll();
			groupMemberActivityDay_collection.removeAll();
			leaderboard_collection.removeAll();
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
		public function clearCurrentGroup(event:UIEvent):void{
			currentGroup = null;
		}
		
		
		
/** -----------------
 * 
 * DATA Services - response handlers
 * 
 * -----------------**/
		
//-----TOKEN-----//
		
/** CREATE TOKEN (login) **/
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
		
/** GET GROUPS **/
		private function user_getGroups_handler(groups:Array):void{
			//master data storage
			for each(var g:Object in groups){
				var tlggroup:TLGGroup = new TLGGroup();
				tlggroup._key = g.key;
				tlggroup._name = g.name;
				if(g.admin == 'true'){
					tlggroup._admin = true;
				}
				if(g.member == 'true'){
					tlggroup._member = true;
				}
				group_collection.addItem(tlggroup);
			}
			//END master data
			
			var uie:UIEvent = new UIEvent(UIEvent.GOT_GROUPS);
			dispatcher.dispatchEvent(uie);
		}

/** GET ACTIVITIES **/
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
				myActivities_collection.addItem(act);
			}
			
			//group activities
			for each(var go:Object in result.groupActivities){
				var tlggroup:TLGGroup = getGroupObjectByKey(go.key);
				for each(var gao:Object in go.activities){
					var gact:Activity = new Activity();
					gact._key = gao.key;
					gact._name = gao.name;
					gact._colour = Number('0x'+gao.colour);
					gact._editable = tlggroup._admin;
					//gact._group = tlggroup;
					activity_collection.addItem(gact);
					tlggroup._activities.addItem(gact);
				}
			}
			//END master data
					
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
			
			updateLeaderboard();
		}

/** UPDATE WORKOUT **/
		private function workout_updateWorkout_handler(result:Object, request:Object):void{
			trace("---w");
			//Master data update
			//workout to update
			var workout:Workout = getWorkoutObjectByKey(result.key);
			var oldDate:Date = new Date(workout._date.fullYear, workout._date.month, workout._date.date);
			var dateBits:Array = request.date.split('-');
			workout._date = new Date(dateBits[0], dateBits[1]-1, dateBits[2]);
			
			
			var dateChanged:Boolean = false;
			if( !utils.compareDates(workout._date, oldDate) ){
				dateChanged = true;
			}
			workout._duration = request.duration;
			workout.setHrsMins(request.duration);
			workout._comment = request.comment;
			workout._activities_collection = new ArrayCollection( [] );
			//Activities
			if(result.activityKey){ //new personal activity
				var o:Object = {'name':result.activityName, 'key':result.activityKey, 'colour':result.activityColour};
				var act:Activity = new Activity();
				act._key = o.key;
				act._name = o.name;
				act._colour = Number('0x'+o.colour);
				activity_collection.addItem(act);
				workout._activities_collection.addItem( act );
			}
			//Other activities
			for each(var ga:String in request.activities){
				var activityObject:Activity = getActivityObjectByKey(ga);
				if(activityObject){
					workout._activities_collection.addItem(activityObject);
				}
			}
			//END Master data update
			
			//Update display collections
			if(dateChanged){
				//rebuild list
				build_workoutDay_collection();
				//update calendar
				var uie:UIEvent = new UIEvent(UIEvent.WORKOUT_DATE_CHANGED);
				uie.workout = workout;
				dispatcher.dispatchEvent(uie);
			}
			
			updateLeaderboard();
			
		}

/** DELETE WORKOUT **/
		private function workout_deleteWorkout_handler(result:Object, request:Object):void{
			//remove from calendar
			var uie:UIEvent = new UIEvent(UIEvent.WORKOUT_DELETED);
			uie.workout = getWorkoutObjectByKey(request.key);
			dispatcher.dispatchEvent(uie);
			
			//Master data
			deleteWorkoutObjectByKey(request.key);
			
			//rebuild list
			build_workoutDay_collection();
			
			//update any group data
			updateLeaderboard();
		}
		
		
//-----GROUP-----//
		
/** GET MEMBER WORKOUTS **/
		private function group_getMemberWorkouts_handler(result:Object, request:Object):void{
			var m:Object;
			
			//Master data
			var groupObject:TLGGroup = getGroupObjectByKey(request.group);
			if(!groupObject._loaded){
				for each(m in result.members){
					trace('-----' + m.name);
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
					
					for each(var a:Object in m.activities){
						//get activity
						var activity:Activity = getActivityObjectByKey(a.activity);
						for each(var sum:Object in a.workoutSummaries){
							//get date and duration
							var gmad:GroupMemberActivityDay = new GroupMemberActivityDay();
							gmad._activity = activity;
							var dateBits:Array = sum.date.split('-');
							gmad._date = new Date(dateBits[0], dateBits[1]-1, dateBits[2]);
							gmad._duration = sum.duration;
							gmad._group = groupObject;
							gmad._user = tlguser;
							//sorting
							gmad._email = tlguser._email; 
							gmad._groupKey = groupObject._key; 
							gmad._activityKey = activity._key; 
							groupMemberActivityDay_collection.addItem(gmad);
						}
					}
				}
				groupObject._loaded = true;
			}
			utils.sortGroupMemberActivityDayCollection(groupMemberActivityDay_collection);
			
			buildLeaderboardData();
			
			//sets leaderboard
			var uie:UIEvent = new UIEvent(UIEvent.GROUP_READY);
			dispatcher.dispatchEvent(uie);
		}
		
		
		

		
//-----ACTIVITY-----//
		
/** ADD ACTIVITY **/
		private function activity_addActivity_handler(result:Object, request:Object):void{
			if(request.group){
				//Master data
				var groupObject:TLGGroup = getGroupObjectByKey(request.group);
				var act:Activity = new Activity();
				act._key = result.key;
				act._name = request.name;
				act._colour = Number('0x'+request.colour);
				act._editable = groupObject._admin;
				
				activity_collection.addItem(act);
				groupObject._activities.addItem(act);
				//END Master data
			}
			
		}
		
/** UPDATE ACTIVITY **/
		private function activity_updateActivity_handler(result:Object, request:Object):void{
			//Master data
			var act:Activity = getActivityObjectByKey(request.key);
			if(act){
				act._colour = Number('0x'+request.colour);
				act._name = request.name;
			}
			//END Master data
			
		}
		private function activity_updateActivity_fail_handler():void{
			var uie:UIEvent = new UIEvent(UIEvent.ACTIVITY_UPDATE_FAIL);
			dispatcher.dispatchEvent(uie);
		}
		
		
		
/** -----------------
 * 
 * TOOLS
 * - Finders, getters, calculators, builders
 * 
 * -----------------**/
		
		private function updateLeaderboard():void{
			leaderboard_collection.removeAll();
			groupMemberActivityDay_collection.removeAll();
			for each(var g:TLGGroup in group_collection){
				g._loaded = false; //causes group to reload when opened
			}
			//if currently on a group, reload now.
			if(currentGroup){
				var uie:UIEvent = new UIEvent(UIEvent.GO_GROUP);
				uie.tlgGroup = currentGroup;
				goGroup(uie);
			}
		}
		
//BUILDERS ---------------------

		private function build_workoutDay_collection():void{
			if(workout_collection.length < 1){ return; }; //kick out of function if no workouts
			//empty collection
			workoutDay_collection = new ArrayCollection([]);
			//work through workout_collection
			var cursor:IViewCursor = workout_collection.createCursor();
			var wd:WorkoutDay = new WorkoutDay();
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
					wd = new WorkoutDay();
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
			
			workoutDay_collection.filterFunction = workoutByMonth_filter;
			workoutDay_collection.refresh();
		}
		
		private function build_workoutMonth_collection():void{
			//empty collection
			workoutMonth_collection = new ArrayCollection([]);
			//work through workoutDay_collection
			var cursor:IViewCursor = workoutDay_collection.createCursor();
			var wm:WorkoutMonth = new WorkoutMonth();
			var wd:WorkoutDay = cursor.current as WorkoutDay;
			wm._date = new Date(wd._date.fullYear, wd._date.month);
			wm._workoutDays.addItem(wd);
			cursor.moveNext();
			
			while (! cursor.afterLast) {
				wd = cursor.current as WorkoutDay;
				if( utils.compareMonths(wd._date, wm._date) ){
					wm._workoutDays.addItem(wd);
				}else{
					workoutMonth_collection.addItem(wm);
					wm = new WorkoutMonth();
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
		
		private function buildLeaderboardData():void{
			//need: group, startDate, endDate
			//TODO: add [activities] and use as filters
			
			//clean start
			leaderboard_collection.removeAll();
			
			//filter input show only currentGroup
			groupMemberActivityDay_collection.filterFunction = currentGroup_filter; //need to do date range...
			groupMemberActivityDay_collection.refresh();
			
			//groupMemberActivityDay_collection should only show items from current group (TODO: and date range)
			var cursor:IViewCursor = groupMemberActivityDay_collection.createCursor();
			//add first item to leaderboard
			var currentItem:GroupMemberActivityDay = cursor.current as GroupMemberActivityDay;
			var li:LeaderboardItem = new LeaderboardItem();
			li._user = currentItem._user;
			li._total = currentItem._duration;
			var actSum:ActivitySummary = new ActivitySummary();
			actSum._activity = currentItem._activity;
			actSum._activity_name = currentItem._activity._name;
			actSum._duration = currentItem._duration;
			li._activitySummaries_collection.addItem(actSum);
			cursor.moveNext();
			
			//go through the rest
			while(!cursor.afterLast){
				currentItem = cursor.current as GroupMemberActivityDay;
				//check member
				if(currentItem._user == li._user){
					li._total = li._total + currentItem._duration; //update total
					//check activity (ac should be sorted by activity)
					if(currentItem._activity == actSum._activity){
						//same activity
						actSum._duration = actSum._duration + currentItem._duration; //update subtotal
					}else{
						//different activity - make new activity summary
						actSum = new ActivitySummary();
						actSum._activity = currentItem._activity;
						actSum._activity_name = currentItem._activity._name;
						actSum._duration = currentItem._duration;
						li._activitySummaries_collection.addItem(actSum);
					}
				}else{
					//different user - new item in leaderboard
					leaderboard_collection.addItem(li); //store current item
					//make new item
					li = new LeaderboardItem();
					li._user = currentItem._user;
					li._total = currentItem._duration;
					actSum = new ActivitySummary();
					actSum._activity = currentItem._activity;
					actSum._activity_name = currentItem._activity._name;
					actSum._duration = currentItem._duration;
					li._activitySummaries_collection.addItem(actSum);
				}
				cursor.moveNext();
			}
			//add last item
			leaderboard_collection.addItem(li);
			
			utils.sortArrayCollection(leaderboard_collection, "_total", true, "DESC");
		}

//GET, SET, DELETE
		public function getGroupObjectByKey(key:String):TLGGroup{
			for each(var group:TLGGroup in group_collection){
				if(group._key == key){
					return group;
				}
			}
			return null;
		}
		public function getWorkoutObjectByKey(key:String):Workout{
			for each(var w:Workout in workout_collection){
				if(w._key == key){
					return w;
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
		public function setWorkoutMonth(event:UIEvent):void{
			selectedMonth = event.date;
			workoutDay_collection.refresh();
		}
		
		
		
		
// Filtering and sorting
			
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
		private function workoutByMonth_filter(w:WorkoutDay):Boolean{
			if(w._date.time >= selectedMonth.time){
				var endDate:Date = new Date(selectedMonth.fullYear, selectedMonth.month+1);
				if(w._date.time < endDate.time){
					return true;
				}
			}
			return false;
		}
		private function currentGroup_filter(gmad:GroupMemberActivityDay):Boolean{
			if(gmad._group == currentGroup){
				return true;
			}
			return false;
		}
	}
}










