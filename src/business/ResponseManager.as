package business{
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	import business.dataObjects.Activity;
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
		//token is used to authenticate this user on every request. Use token.creatToken to log in and get a new token.
		[Bindable] public var token:String;
		[Bindable] public var userName:String; //returned when someone logs in
		[Bindable] public var userEmail:String;
		[Bindable] public var myGroups:Array; //array of groups I am a member of
		[Bindable] public var myActivities:Array; //array of personal activities
		[Bindable] public var myActivities_collection:ArrayCollection; //array of personal activities
		//[Bindable] public var myWorkouts:Array;  //all the workouts in a single pile. The master version of the data
		
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
					case "token.createToken":
						token = result.token;
						userName = result.name;
						userEmail = request.email;
						token_createToken_handler();
						break;
					//USER
					case "user.getGroups":
						myGroups = result.groups;
						user_getGroups_handler();
						break;
					case "user.getActivities":
						user_getActivities_handler(result.activities);
						break;
					case "user.getAllWorkouts":
						user_getAllWorkouts_handler(result.workouts);
						break;
					//WORKOUT
					case "workout.addWorkout":
						Alert.show("Workout added","Success");
						workout_addWorkout_handler(result, request);
						break;
					case "workout.updateWorkout":
						workout_updateWorkout_handler(result, request);
						break;
					//ACTIVITY
					case "activity.updateActivity":
						activity_updateActivity_handler(result.workouts);
						break;
					default:
						break;
				}
				
				
				
			}else{
				Alert.show(String(result.message), "Something went wrong");
				switch(operation){
					case "activity.updateActivity":
						activity_updateActivity_fail_handler(result.workouts);
						break;
					default:
						break;
				}
			}
		}
		
		public function handleFault(event:RequestEvent, fault:Object, resultObject:Object):void{
			Alert.show(String(fault), "Error");
			
		}
		
		
		public function logout():void{
			//clear all data
			token = '';
			userName = '';
			myGroups = [];
			myActivities = [];
			//myWorkouts = [];
		}
		
//-----TOKEN-----//
		private function token_createToken_handler():void{
			var uie:UIEvent = new UIEvent(UIEvent.USER_LOGGED_IN);
			dispatcher.dispatchEvent(uie);
		}
		
//-----USER-----//
		private function user_getGroups_handler():void{
			var uie:UIEvent = new UIEvent(UIEvent.GOT_GROUPS);
			dispatcher.dispatchEvent(uie);
		}
		private function user_getActivities_handler(activities:Array):void{
			myActivities = new Array();
			for each(var o:Object in activities){
				var a:Activity = new Activity(o);
				myActivities.push(a);
			}
			
			//sort
			myActivities.sortOn('_name', Array.CASEINSENSITIVE);
			myActivities_collection = new ArrayCollection(myActivities);
			
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
					for each(var a:Activity in myActivities){
						if(a._key == i.key){
							activities.push(a);
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
			var firstActivity:Activity; //Until GROUPS, there will only be one
			if(result.activityKey){
				var o:Object = {'name':result.activityName, 'key':result.activityKey, 'colour':result.activityColour};
				firstActivity = new Activity(o);
				
				//add to collection
				myActivities_collection.addItem(firstActivity);
				//sort by _name
				utils.sortArrayCollection(myActivities_collection, '_name');
				
			}else{
				for each(var a:Activity in myActivities){
					if(a._key == request.activity){
						firstActivity = a;
						break;
					}
				}
			}
			
			
			//Add workout locally
			var activities:Array = [];
			if(firstActivity){ activities.push(firstActivity); };
			
			var wo:Object = new Object();
			wo.key = result.key;
			wo.date = request.date;
			wo.duration = request.duration;
			wo.comment = request.comment;
			
			var w:Workout = new Workout(wo, activities);

			//add to workoutDaysByMonth_collection which should update UI
			addWorkoutToCollection(w);
			
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
		
/////////////////////////
		
		private function workout_updateWorkout_handler(result:Object, request:Object):void{
			var uie:UIEvent;
			//sort out the activity
			var firstActivity:Activity; //Until GROUPS, there will only be one
			if(result.activityKey){
				//New Activity
				var o:Object = {'name':result.activityName, 'key':result.activityKey, 'colour':result.activityColour};
				firstActivity = new Activity(o);
				
				//add to collection
				myActivities_collection.addItem(firstActivity);
				//sort by _name
				utils.sortArrayCollection(myActivities_collection, '_name');
				
			}else{
				//Existing activity
				for each(var a:Activity in myActivities){
					if(a._key == request.activity){
						firstActivity = a;
						break;
					}
				}
			}
			
			
			//workout Object
			var wo:Object = new Object();
			wo.key = result.key;
			wo.date = request.date;
			wo.duration = request.duration;
			wo.comment = request.comment;
			
			var workoutDateChanged:Boolean = false;
			var workoutToShift:Workout;
			//find and remove local workout
			for each(var wm:WorkoutMonth in workoutDaysByMonth_collection){
				var dayCount:int = 0;
				for each(var wd:WorkoutDay in wm._workoutDays_collection){
					

					
					
					for(var i:int = 0; i<wd._workouts_collection.length; i++){
						if(result.key == wd._workouts_collection.getItemAt(i)._key){
							wd._workouts_collection.getItemAt(i).updateWorkout(wo, [firstActivity]);
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
		}

		
		
		
//-----ACTIVITY-----//
		private function activity_updateActivity_handler(result:Object):void{
			var uie:UIEvent = new UIEvent(UIEvent.ACTIVITY_UPDATED);
			dispatcher.dispatchEvent(uie);
			
		}
		private function activity_updateActivity_fail_handler(result:Object):void{
			var uie:UIEvent = new UIEvent(UIEvent.ACTIVITY_UPDATE_FAIL);
			dispatcher.dispatchEvent(uie);
		}
		
		
	}
}