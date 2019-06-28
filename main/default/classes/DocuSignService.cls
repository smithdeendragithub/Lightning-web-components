/**
 * Service class for interacting with DocuSign web services. All operations
 * provided by an instance of this class are scoped to the passed in account,
 * and are executed using the passed in credentials.
 * 
 * @author Scott Faucera
 */
public with sharing class DocuSignService {

	/**
	* The default callout timeout for the service calls
	*/
	private static final Integer DEFAULT_CALLOUT_TIMEOUT = 60;

	/**
	 * the DocuSign account ID for this instance
	 */
	private String accountId;
	
	/**
	 * the DocuSign user ID for this instance
	 */
	private String userId;
	
	/**
	 * the DocuSign password for this instance
	 */
	private String password;
	
	/**
	 * the DocuSign integrator key for this instance
	 */
	private String integratorKey;
	
	/**
	 * the endpoint URL for the DocuSign service API
	 */
	private String apiEndpoint;
	
	/**
	 * the endpoint URL for the DocuSign account management API
	 */
	private String accountManagementEndpoint;
	
	/**
	 * the endpoint URL for the DocuSign credential API
	 */
	private String credentialEndpoint;
	
	/**
	* the callout timeout for service calls
	*/
	private Integer timeout;
	
	/**
	 * proxy instance for the service API
	 */
	private DocuSignAPI.APIServiceSoap apiServiceSoap;
	
	/**
	 * proxy instance for the account management API
	 */
	private DocuSignAccountManagementAPI.AccountManagementServiceSoap accountManagementServiceSOAP;
	
	/**
	 * proxy instance for the credential API
	 */
	private DocuSignCredentialAPI.CredentialSoap credentialSoap;
	
	/**
	 * Overload constructor.
	 * 
	 * @param accountId
	 *            the DocuSign account ID
	 * @param userId
	 *            the DocuSign user ID
	 * @param password
	 *            the DocuSign password
	 * @param integratorKey
	 *            the DocuSign integrator key
	 * @param apiEndpoint
	 *            the endpoint URL for the DocuSign service API
	 * @param accountManagementEndpoint
	 *            the endpoint URL for the DocuSign account management API
	 * @param credentialEndpoint
	 *			  the endpoint URL for the DocuSign credential API 
	 * @throws DocuSignServiceException
	 *            on any failure
	 */      
	public DocuSignService(String accountId, String userId, String password, String integratorKey, 
						   String apiEndpoint, String accountManagementEndpoint, String credentialEndpoint) {
		this(accountId, userId, password, integratorKey, DEFAULT_CALLOUT_TIMEOUT, apiEndpoint, accountManagementEndpoint, credentialEndpoint);
	}
	
	/**
	 * Overload constructor.
	 * 
	 * @param accountId
	 *            the DocuSign account ID
	 * @param userId
	 *            the DocuSign user ID
	 * @param password
	 *            the DocuSign password
	 * @param integratorKey
	 *            the DocuSign integrator key
	 * @param timeout
	 *            the timeout (in seconds) for any DocuSign service calls
	 * @param apiEndpoint
	 *            the endpoint URL for the DocuSign service API
	 * @param accountManagementEndpoint
	 *            the endpoint URL for the DocuSign account management API
	 * @param credentialEndpoint
	 *			  the endpoint URL for the DocuSign credential API 
	 * @throws DocuSignServiceException
	 *            on any failure
	 */      
	public DocuSignService(String accountId, String userId, String password, String integratorKey, Integer timeout,
						   String apiEndpoint, String accountManagementEndpoint, String credentialEndpoint) {
		
		// validate parameters
		if(accountId == null || userId == null || password == null || integratorKey == null || timeout == null ||
		   apiEndpoint == null || accountManagementEndpoint == null || credentialEndpoint == null) {
			throw new DocuSignServiceException('Parameters must not be null.');
		}
		
		// store with instance
		this.accountId = accountId;
		this.userId = userId;
		this.password = password;
		this.integratorKey = integratorKey;
		this.timeout = (timeout < 0 ? 0 : timeout);
		this.apiEndpoint = apiEndpoint;
		this.accountManagementEndpoint = accountManagementEndpoint;
		this.credentialEndpoint = credentialEndpoint;
		
		// create and store our clients
		this.apiServiceSoap = createApiServiceSoap();
		this.accountManagementServiceSOAP = createAccountManagementServiceSoap();
		this.credentialSoap = createCredentialSoap();
	}
	
	/**
	 * Determines if the current user is a member of the account represented by
	 * this service instance.
	 * 
	 * @return true if a member, false otherwise
	 * @throws DocuSignServiceException
	 *             on any failure
	 */
	public Boolean isCurrentUserAnAccountMember() {
		
		// get the current user's email
		String email = getCurrentUserEmail();
		
		// if current user does not have an email, throw an exception
		if(email == null) {
			throw new DocuSignServiceException('Unable to determine if current user is a DocuSign account member.  ' +
				'Error: The current user does not have a valid Salesforce email address.');
		}
		
		// return status to caller
		return isUserAnAccountMember(email);
	}
	
	/**
	 * Determines if a user is a member of the account represented by this
	 * service instance.
	 * 
	 * @param email
	 *            the email of the user to check
	 * @return true if a member, false otherwise
	 * @throws DocuSignServiceException
	 *             on any failure
	 */
	public Boolean isUserAnAccountMember(String email) {
		
		Boolean isMember = false;
		
		// if user does not have an email, throw an exception
		if(email == null) {
			throw new DocuSignServiceException('Parameters must not be null.');
		}
		
		// if we have an email, check via the API
		DocuSignAccountManagementAPI.CheckAccountMemberResult_element response = null;
		try {
			
			// make the call
			response = accountManagementServiceSOAP.CheckAccountMember(this.accountId, email);
		
			// set flag from response
			isMember = 'true'.equalsIgnoreCase(response.Status);
			
		} catch(Exception e) {
			throw new DocuSignServiceException('Unable to determine if user is a DocuSign account member.  Error: ' + e.getMessage());
		}

		// return status
		return isMember;
	}
	
	/**
	 * Determines if the current user is an active company member of the account
	 * represented by this service instance.  Please note that this method call
	 * currently requires the system administrator privilige (subject to change).
	 * 
	 * @return true if user is an active company member, otherwise false
	 * @throws DocuSignServiceException
	 *             on any failure
	 */
	public Boolean isCurrentUserAnActiveCompanyMember() {
		
		// get the current user's email
		String email = getCurrentUserEmail();
		
		// if current user does not have an email, throw an exception
		if(email == null) {
			throw new DocuSignServiceException('Unable to determine if current user is an active DocuSign company user.  ' +
				'Error: The current user does not have a valid Salesforce email address.');
		}
		
		// return status to caller
		return isUserAnActiveCompanyMember(email);
	}
	
	/**
	 * Determines if the specified user is an active company member of the
	 * account represented by this service instance.  Please note that this 
	 * method call currently requires the system administrator privilige 
	 * (subject to change).
	 * 
	 * @param email
	 *            the email of the user to check
	 * @return true if user is an active company member, otherwise false
	 * @throws DocuSignServiceException
	 *             on any failure
	 */
	public Boolean isUserAnActiveCompanyMember(String email) {
		
		Boolean isActiveCompanyUser = false;
		
		// if user does not have an email, throw an exception
		if(email == null) {
			throw new DocuSignServiceException('Parameters must not be null.');
		}
		
		DocuSignAccountManagementAPI.GetMembershipSummaryResult_element response;
		try {
			
			// make the call
			response = accountManagementServiceSOAP.GetMembershipSummary(email);
			
		} catch(Exception e) {
			throw new DocuSignServiceException('Unable to determine if user is an active DocuSign company user.  Error: ' + e.getMessage());
		}
		
		// if our response failed, throw an exception
		if(!response.Success) {
			throw new DocuSignServiceException('Unable to determine if user is an active DocuSign company user.  Error: ' + response.Error.Description);
		}
		
		// iterate members and find the one associated with this account
		for(DocuSignAccountManagementAPI.MembershipSummary summary : response.MembershipSummaries.MembershipSummary) {
			
			// if the member is for our account...
			if(this.accountId.equalsIgnoreCase(summary.AccountId)) {
				
				// ... set the status
				isActiveCompanyUser = ('CompanyUser'.equalsIgnoreCase(summary.UserType) && 'Active'.equalsIgnoreCase(summary.UserStatus));
				break;
			}
		}

		// return status
		return isActiveCompanyUser;
	}
	
	/**
	 * Adds the current user as member of the account represented by this
	 * service instance. The member is created with default permissions, the
	 * exception being the addition of the Send Envelope permission.
	 * 
	 * @throws DocuSignServiceException
	 *             on any failures
	 */
	public void addCurrentUserAsAccountMember() {
		
		// get the current user's email
		String email = getCurrentUserEmail();
		
		// throw exception if we don't have an email
		if(email == null) {
			throw new DocuSignServiceException('Unable to add current user as a DocuSign account member.  ' +
				'Error: The current user does not have a valid Salesforce email address.');
		}
		
		// create the member
		DocuSignAccountManagementAPI.Member member = new DocuSignAccountManagementAPI.Member();
		member.MemberEmailAddress = email;
		member.MemberFirstName = Userinfo.getFirstName();
		member.MemberLastName = Userinfo.getLastName();
		member.MemberUserName = Userinfo.getName();  //Userinfo.getUserName();
		
		/*
		    the password settings below are required to leverage the automatic account activation
		    features of DocuSign, however, they are commented out pending further analysis.  when
		    not supplied, the user is required to activate via an email sent from DocuSign.
		    
		 */
		member.MemberPassword = 'pwd' + Math.random();
		member.MemberForgottenPasswordQuestion = 'How much wood could a woodchuck chuck if a woodchuck could chuck wood?';
		member.MemberForgottenPasswordAnswer  = 'As much as it can: ' + Math.random();
		
		member.MemberSettings = new DocuSignAccountManagementAPI.MemberSettings();
		member.MemberSettings.CanSendEnvelope = true;
		DocuSignAccountManagementAPI.ArrayOfMember arrayOfMember = new DocuSignAccountManagementAPI.ArrayOfMember();
		arrayOfMember.Member = new DocuSignAccountManagementAPI.Member[] { member };
		
		DocuSignAccountManagementAPI.AddMembersToAccountResult_element response = null;
		try {
			
			// make the call
			response = accountManagementServiceSOAP.AddMembersToAccount(this.accountId, arrayOfMember);
		}
		catch(Exception e) {
			throw new DocuSignServiceException('Unable to add current user as a DocuSign account member.  Error: ' + e.getMessage());
		}
		
		// throw an exception if we were not successful (todo: we may need to 
		// check returned member array size, as the call seems to return success
		// even though a member was not created - maybe the case on a second call for same user??)
		if(!response.Success) {
			throw new DocuSignServiceException('Unable to add current user as a DocuSign account member.  Error: ' + response.Error.Description);
		}
	}
	
	/**
	 * Authenticates a user with DocuSign using the passed in user credentials.
	 * 
	 * @param email
	 *            the email of the user to authenticate
	 * @param password
	 *            the password of the user to authenticate
	 * @throws DocuSignAuthenticationException
	 *             on authentication failure
	 * @throws DocuSignServiceException
	 *             on all other failures
	 */
	public void authenticateUser(String email, String password) {
		
		if(email == null || password == null) {
			throw new DocuSignServiceException('Parameters must not be null.');
		}
		
		DocuSignCredentialAPI.LoginResult_element response = null;
		try {
			
			// make the call
			response = credentialSoap.Login(email, password);
			
		} catch(Exception e) {
			throw new DocuSignServiceException('Unable to authenticate DocuSign user.  Error: ' + e.getMessage());
		}
		
		// throw an exception if we were not successful
		if(!response.Success) {
			throw new DocuSignAuthenticationException('Unable to authenticate DocuSign user.  Error: ' + response.AuthenticationMessage);
		}
	}
	
	/**
	 * Gets the currently logged in user's email address from Salesforce
	 * 
	 * @return the current user's email, or null if it does not exist
	 */
	private String getCurrentUserEmail() {
		return [Select Email From User Where Id = :UserInfo.getUserId() LIMIT 1].get(0).Email;	
	}
	
	
	/**
	 * Creates a client proxy for the service API.
	 * 
	 * @return a configured APIServiceSoap instance
	 */
	private DocuSignAPI.APIServiceSoap createApiServiceSoap() {
		
		// create the proxy
		DocuSignAPI.APIServiceSoap apiServiceSoap = new DocuSignAPI.APIServiceSoap();
		
		// set parameters
		apiServiceSoap.endpoint_x = apiEndpoint;
		apiServiceSoap.timeout_x = timeout * 1000;

		// create and attach username token
		String usernameToken = '<DocuSignCredentials><Username>'+ userId
	            +'</Username><Password>' + password
	            + '</Password><IntegratorKey>' + integratorKey
	            + '</IntegratorKey></DocuSignCredentials>';
        apiServiceSoap.inputHttpHeaders_x = new Map<String, String>();
        apiServiceSoap.inputHttpHeaders_x.put('X-DocuSign-Authentication', usernameToken);
        
        // return proxy
        return apiServiceSoap;
	}
	
	/**
	 * Creates a client proxy for the service API.
	 * 
	 * @return a configured APIServiceSoap instance
	 */
	private DocuSignAccountManagementAPI.AccountManagementServiceSoap createAccountManagementServiceSoap() {
		
		// create the proxy
		DocuSignAccountManagementAPI.AccountManagementServiceSoap accountManagementServiceSoap = new DocuSignAccountManagementAPI.AccountManagementServiceSoap();
		
		// set parameters
		accountManagementServiceSoap.endpoint_x = accountManagementEndpoint;
		accountManagementServiceSoap.timeout_x = timeout * 1000;

		// create and attach username token
		String usernameToken = '<DocuSignCredentials><Username>'+ userId
	            +'</Username><Password>' + password
	            + '</Password><IntegratorKey>' + integratorKey
	            + '</IntegratorKey></DocuSignCredentials>';
        accountManagementServiceSoap.inputHttpHeaders_x = new Map<String, String>();
        accountManagementServiceSoap.inputHttpHeaders_x.put('X-DocuSign-Authentication', usernameToken);
        
        // return proxy
        return accountManagementServiceSoap;
	}
	
	/**
	 * Creates a client proxy for the service API.
	 * 
	 * @return a configured APIServiceSoap instance
	 */
	private DocuSignCredentialAPI.CredentialSoap createCredentialSoap() {
		
		// create the proxy
		DocuSignCredentialAPI.CredentialSoap credentialSoap = new DocuSignCredentialAPI.CredentialSoap();
		
		// set parameters
		credentialSoap.endpoint_x = credentialEndpoint;
		credentialSoap.timeout_x = timeout * 1000;

		// create and attach username token
		String usernameToken = '<DocuSignCredentials><Username>'+ userId
	            +'</Username><Password>' + password
	            + '</Password><IntegratorKey>' + integratorKey
	            + '</IntegratorKey></DocuSignCredentials>';
        credentialSoap.inputHttpHeaders_x = new Map<String, String>();
        credentialSoap.inputHttpHeaders_x.put('X-DocuSign-Authentication', usernameToken);
        
        // return proxy
        return credentialSoap;
	}
	
	/**
	 * Exception indicating a DocuSignService failure. 
	 */
	public virtual class DocuSignServiceException extends Exception {
	}
	
	/**
	 * Exception indicating a failed DocuSignService authentication attempt. 
	 */
	public class DocuSignAuthenticationException extends DocuSignServiceException {
	}
}