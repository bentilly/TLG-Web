package events{
	import flash.events.Event;
	
	public class RequestEvent extends Event{
		
		public static const TLG_API_REQUEST:String = "tlg_api_request_event";
		
		public var requestJson:String;
		
		
		public function RequestEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}
	}
}