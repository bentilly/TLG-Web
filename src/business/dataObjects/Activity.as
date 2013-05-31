package business.dataObjects
{

	public class Activity
	{
		
		public var _key:String;
		[Bindable] public var _name:String;
		[Bindable] public var _colour:Number;
		[Bindable] public var _editable:Boolean = false;
		public var _group:TlgGroup = null; //reference to the parent group of this activity. Stays null if its a personal activity
		
		
		public function Activity(o:Object)
		{
			_key = o.key;
			_name = o.name;
			_colour = Number('0x'+o.colour);

		}
	}
}