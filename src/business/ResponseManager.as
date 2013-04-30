package business{
	import flash.events.IEventDispatcher;

	import mx.controls.Alert;
	
	import business.data.Activity;
	import business.data.Workout;
	
	import events.RequestEvent;
	import events.UIEvent;
	
	
	
	
	
	public class ResponseManager{
		
		/*** INTERNAL ***/
		private var dispatcher:IEventDispatcher;
		
		
		/*** EXPORT ***/
		//token is used to authenticate this user on every request. Use token.creatToken to log in and get a new token.
		[Bindable] public var token:String;
		[Bindable] public var userName:String; //returned when someone logs in
		[Bindable] public var myGroups:Array; //array of groups I am a member of
		[Bindable] public var myActivities:Array; //array of personal activities
		[Bindable] public var myWorkouts:Array;
		
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
						token_createToken_handler();
						break;
					case "user.getGroups":
						myGroups = result.groups;
						user_getGroups_handler();
						break;
					case "user.getActivities":
						user_getActivities_handler(result.activities);
						break;
					case "workout.addWorkout":
						Alert.show("Workout added","Success");
						workout_addWorkout_handler(result, request);
						break;
					case "workout.updateWorkout":
						workout_updateWorkout_handler(result, request);
						break;
					case "user.getAllWorkouts":
						user_getAllWorkouts_handler(result.workouts);
						break;
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
			myWorkouts = [];
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
			myWorkouts = new Array();
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
				
				
				var w:Workout = new Workout(o, activities);
				myWorkouts.push(w);
			}
			//sort
			myWorkouts.sortOn('_date');
			
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
				myActivities.push(firstActivity);
				
				//sort
				myActivities.sortOn('_name', Array.CASEINSENSITIVE);
				
				uie = new UIEvent(UIEvent.ACTIVITIES_UPDATED);
				dispatcher.dispatchEvent(uie);
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
			myWorkouts.push(w);
			
			uie = new UIEvent(UIEvent.WORKOUT_ADDED);
			uie.workout = w;
			dispatcher.dispatchEvent(uie);
		}
		
		private function workout_updateWorkout_handler(result:Object, request:Object):void{
			var uie:UIEvent;
			//sort out the activity
			var firstActivity:Activity; //Until GROUPS, there will only be one
			if(result.activityKey){
				var o:Object = {'name':result.activityName, 'key':result.activityKey, 'colour':result.activityColour};
				firstActivity = new Activity(o);
				myActivities.push(firstActivity);
				
				//sort
				myActivities.sortOn('_name', Array.CASEINSENSITIVE);
				
				uie = new UIEvent(UIEvent.ACTIVITIES_UPDATED);
				dispatcher.dispatchEvent(uie);
			}else{
				for each(var a:Activity in myActivities){
					if(a._key == request.activity){
						firstActivity = a;
						break;
					}
				}
			}
			
			//find and update local workout
			var activities:Array = [];
			if(firstActivity){ activities.push(firstActivity); };
			var wo:Object = new Object();
			wo.key = result.key;
			wo.date = request.date;
			wo.duration = request.duration;
			wo.comment = request.comment;
			
			var updatedWorkout:Workout;
			for each(var w:Workout in myWorkouts){
				if(result.key == w._key){
					w.updateWorkout(wo, activities);
					updatedWorkout = w;
					break;
				}
			}
			
			//sort myWorkouts
			myWorkouts.sortOn('_date');
			
			uie = new UIEvent(UIEvent.WORKOUT_UPDATED);
			uie.workout = updatedWorkout;
			dispatcher.dispatchEvent(uie);
			
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