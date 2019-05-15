public with sharing class integraWSEndpointMediator {
	
    private static integraWS.BasicHttpBinding_ISalesForceServiceEndPoint ep {get; private set;}
    class integrationException extends Exception {}
    public static Boolean simulateIntegrationException = false;
    
    public static integraWS.BasicHttpBinding_ISalesForceServiceEndPoint Endpoint{
    	get{
    		if(ep == null){
    			ep = new integraWS.BasicHttpBinding_ISalesForceServiceEndPoint();
		        ep.timeout_x = CustomSettingUtils.WSTimeout;
		        ep.endpoint_x = CustomSettingUtils.IntegraWSEndpoint;
    		}
    		
    		return ep;
    	}
    }
    
    private static String sysAdminId;
    public static String SystemAdminID{
    	get{
    		if(sysAdminId == null){
    			Profile s = [select Id from Profile where Name = 'System Administrator'];
    			sysAdminId = s != null ? s.Id : '';
    		}
    		return sysAdminId;
    	}
    }
    
    public static Boolean canRunIntegrationUpdate(String processName){
		Boolean disabled = false;
		for(String val : CustomSettingUtils.getProcessConfigurationValues('IntegrationUpdateDisabled', processName)){
			if(val != null){
				disabled |= val.toLowercase() == 'true';																						//Disabled for all
				disabled |= val.toLowercase() == 'sysadminmode' && UserInfo.getProfileId() == SystemAdminID;									//Disabled for sys admins
				disabled |= (val.length() == 15 || val.length() == 18) && UserInfo.getUserId().toLowerCase().startsWith(val.toLowerCase());		//Disabled for this user
			}
		}
		return !disabled;
    }
    
    public static Boolean integrationEnabled(){
    	if(Test.IsRunningTest()){
    		if(simulateIntegrationException)
    			throw new integrationException('Testing exception!');
    		return false;
    	}
    	return !string.IsEmpty(Endpoint.endpoint_x);
    }
}