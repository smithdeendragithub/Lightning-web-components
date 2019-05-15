public class UserNotesControllerExtension {
    
    public Id DelRecordID {get; set;}
    private Id UserID;
    private List<User_Note__c> results = new List<User_Note__c>();
    private String sortOrder = 'DESC';
    private String sortBy = 'LastModifiedDate'; 
    
    // Sorting Methods for the columns of the PageBlockTable
    public void sortComments(){
        if (sortBy.equals('Name')){
            sortOrder = sortOrder.equals('ASC') ? 'DESC' : 'ASC'; 
        }
        else {
            sortOrder = 'ASC';
        }
        this.sortBy = 'Name'; 
    }
    
    public void sortModifiedBy(){
        if (sortBy.equals('LastModifiedById')){
            sortOrder = sortOrder.equals('ASC') ? 'DESC' : 'ASC'; 
        }
        else {
            sortOrder = 'ASC';
        }
        this.sortBy = 'LastModifiedById'; 
    }
    
    public void sortDateModified(){
        if (sortBy.equals('LastModifiedDate')){
            sortOrder = sortOrder.equals('ASC') ? 'DESC' : 'ASC'; 
        }
        else {
            sortOrder = 'DESC';
        }
        this.sortBy = 'LastModifiedDate'; 
    }
    
    public void sortDateCreated(){
        if (sortBy.equals('CreatedDate')){
            sortOrder = sortOrder.equals('ASC') ? 'DESC' : 'ASC'; 
        }
        else {
            sortOrder = 'DESC';
        }
        this.sortBy = 'CreatedDate'; 
    }
    
    public UserNotesControllerExtension(ApexPages.StandardController stdControl){
        UserID = stdControl.getRecord().Id;
    }
    
    // Retrieve User Notes records for the respective User by filtering the User's ID
    public List<User_Note__c> getNotes() {
        results = Database.query('SELECT Name, Id, LastModifiedDate, CreatedDate, LastModifiedById, User__c FROM User_Note__c WHERE User__c =: UserID ' +
                                 'ORDER BY ' + sortBy + ' ' + sortOrder);
        return results;
    }
    
    public void RemoveNote(){
        if (DelRecordID == null){
            System.debug('null ID was returned, could not delete record.');
        } 
        else {
            delete new User_Note__c(Id = DelRecordID);
        }
    }
    
    public void setUserID(Id num){
        this.UserID = num;
    }
    
    public Id getUserID(){
        return this.UserID;
    }
}