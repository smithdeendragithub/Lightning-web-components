public class UserNotesRecordControllerExtension {
    
    private Id UserID;
    private User result = new User();
    private User_Note__c record = new User_Note__c();
    
    public UserNotesRecordControllerExtension(ApexPages.StandardController stdControl){
        // Get user parameter from the window URL
        UserID = System.currentPagereference().getParameters().get('user');
        record = (User_Note__c)stdControl.getRecord();
    }
    
    public void CustomSave(){
        record.User__c = UserID;
        if (record.Name != null){
            upsert record;
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Note cannot be left blank'));
        }
    }
    
    public User getUserName(){
        result = [SELECT Id, FirstName, LastName FROM User WHERE Id =: UserID];
        return result;
    }
    
    // Function to determine when to close the window, Function only invoked when Save button is pressed.
    public String getCloseWindow(){
        if (record.Name != null)
            return 'window.close()';
        return null;
    }
    
    // Some used for testing purposes
    public void setUserID(Id num){
        this.UserID = num;
    }
    
    public Id getUserID(){
        return this.UserID;
    }
    
    public void setrecord(User_Note__c rec){
        this.record = rec;
    }
    
    public User_Note__c getrecord(){
        return this.record;
    }
}