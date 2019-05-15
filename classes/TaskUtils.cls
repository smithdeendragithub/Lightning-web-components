public class TaskUtils { 
	
	public static Task CreateTask(Id Owner, string Subject, Id WhatId, string Type, Date ActivityDate, Date ReminderDate, string Description, boolean SetReminder, string Status, string WhoId){
		Task t = new Task();
		t.OwnerId = Owner;
		t.Subject = Subject;
		if(WhatId != null)
			t.WhatId = WhatId;
		t.Type = Type;
		t.ActivityDate = ActivityDate;
		t.ReminderDateTime = ReminderDate;
		t.Description = Description;
		t.IsReminderSet = SetReminder;
		t.status = Status;
		if(WhoId != null)
			t.whoid = WhoId;
		return t;
	}
}