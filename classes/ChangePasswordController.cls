/**
 * An apex page controller that exposes the change password functionality
 */
public with sharing class ChangePasswordController implements TestUtils.ITestableClass {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}        
    
    public PageReference changePassword() {
        return Site.changePassword(newPassword, verifyNewPassword, oldpassword);    
    }     
    
   	public ChangePasswordController() {}
	
	/* TestUtils.ITestableClass methods */
	public TestUtils.TestClass getTestClass(){ return new Test_ChangePassword(); }
}