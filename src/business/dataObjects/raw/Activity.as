package business.dataObjects.raw
{

	public class Activity
	{
		public var _key:String;
		[Bindable] public var _name:String;
		[Bindable] public var _colour:Number;
		public var _group:TLGGroup = null; //stays null for personal activities
		//public var _groupData:Group_Data; //old
		[Bindable] public var _editable:Boolean = false;
		
		public function Activity()
		{
		}
	}
}