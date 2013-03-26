package business{
	import flash.events.IEventDispatcher;
	
	import mx.controls.Alert;
	
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
		
		public function ResponseManager(dispatcher:IEventDispatcher){
			this.dispatcher = dispatcher; //creates a dispatcher so this class can send events. Initiated in TLGEventMap.mxml
			trace("ResponseManager Initialised");
			
		}
		
		public function handleResponse(event:RequestEvent, resultObject:Object):void{
			//Get Operation
			var request:Object = JSON.parse(String(event.requestJson));
			var operation:String = request.operation;
			trace("........API RESPONSE.......");
			trace("request = "+request.operation);
			
			//Parse response JSON
			try{
				var result:Object = JSON.parse(String(resultObject));
				trace("response = "+resultObject);
				
			}catch(e:Error){
				trace(e);
			}
			
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
						myActivities = result.activities;
						user_getActivities_handler();
						break;
					case "workout.addWorkout":
						Alert.show("Workout added","Success");
						workout_addWorkout_handler();
						break;
					default:
						break;
				}
				
				
				
			}else{
				Alert.show(String(result.message), "Something went wrong");
			}
			
			
			
		}
		
		public function handleFault(event:RequestEvent, fault:Object, resultObject:Object):void{
			Alert.show(String(fault), "Error");
			
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
		private function user_getActivities_handler():void{
			var uie:UIEvent = new UIEvent(UIEvent.GOT_MY_ACTIVITES);
			dispatcher.dispatchEvent(uie);
		}
		//-----WORKOUT-----//
		private function workout_addWorkout_handler():void{
			var uie:UIEvent = new UIEvent(UIEvent.WORKOUT_ADDED);
			dispatcher.dispatchEvent(uie);
		}
		
		
		
		
		
	}
}