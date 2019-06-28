/**
* Utility class containing general purpose functions for use in the
* Apex environment.
*/
public with sharing class ApexUtils implements TestUtils.ITestableClass {
    
    public static String numberToOrdinal(String nbr) {
        if (nbr.endsWith('1') && nbr != '11') {
            return nbr + 'st';
        } else if (nbr.endsWith('2') && nbr != '12') {
            return nbr + 'nd';
        } else if (nbr.endsWith('3') && nbr != '13') {
            return nbr + 'rd';
        } else {
            return nbr + 'th';
        }
        
        return '';
    }
    
    public static void messageDisplay(String Msg){
        ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, Msg);
        ApexPages.addMessage(m);
    }

    public static void infoMessageDisplay(String Msg){
        ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.INFO, Msg);
        ApexPages.addMessage(m);
    }
    
    public static string getParam(string paramName) {
        return ApexPages.currentPage().getParameters().get(paramName);
    }
    
    public static List<sObject> retrieveFullObjects(sObjectType objType, String whereClause) {
        return retrieveFullObjects(objType, whereClause, null);
    }
    
    public static List<sObject> retrieveFullObjects(sObjectType objType, String whereClause, String orderClause) {
        return retrieveObjectsFromFieldSet(objType, SchemaUtils.RetrieveFullObjectFieldSet(objType), whereClause, orderClause);
    }
    
    public static List<sObject> retrieveObjectsFromFieldSets(sObjectType objType, List<Set<String>> fieldSets, String whereClause, String orderClause) {
        Set<String> mergedSet = new Set<String>();
        for(Set<String> s : fieldSets){
            for(String str : s)
                mergedSet.add(str);
        }
        
        return retrieveObjectsFromFieldSet(objType, mergedSet, whereClause, orderClause);
    }
    
    public static List<sObject> retrieveObjectsFromFieldSet(sObjectType objType, Set<String> fieldSet, String whereClause, String orderClause) {
        fieldSet.add('Id'); //Always include id
        Schema.Describesobjectresult r = objType.getDescribe(); 
        String query = 'select ' + string.join(new List<String>(fieldSet), ', ') + ' from ' + r.getName() + ' where ' + whereClause + (orderClause != null ? ' ORDER BY ' + orderClause : '');
        System.debug(query);
        
        return Database.query(query);
    }
        
    /**************************************************************************/
    /*builds basic email of type text or html - no template inplimentation yet*/
    /**************************************************************************/
    
    private static id pITAdminId = null;
    public static Id ITAdminId{
        get{
            if(pITAdminId == null){
                List<User> us = [select Id from User where email = 'itcrmteam@integratelecom.com'];
                if(us.size() > 0) pITAdminId = us[0].Id;
            }
            return pITAdminId == null? UserInfo.getUserId() : pITAdminId;
        }
    }

    public static Messaging.Singleemailmessage createEmailMessage(Id toUserID, String[] cc, String subject, String body, Boolean isHtml, String replyTo){
        
        Messaging.SingleEmailMessage mail = buildEmailMessage(cc, subject, body, isHtml, replyTo);

        mail.setTargetObjectId(toUserID);
        mail.saveAsActivity = false;

        return mail;
    }
    
    public static Messaging.Singleemailmessage createEmailMessage(String[] to, String[] cc, String subject, String body, Boolean isHtml, String replyTo){
         
        Messaging.SingleEmailMessage mail = buildEmailMessage(cc, subject, body, isHtml, replyTo);

        List<User> toUser = to.size() == 1 ? [select Id from User where Email = :to.get(0) limit 1] : null;
        if(toUser != null && toUser.size() > 0){
            mail.setTargetObjectId(toUser.get(0).Id);
            mail.saveAsActivity = false;
        }
        else
            mail.setToAddresses(to);

        return mail;
    }
    
    public static Messaging.Singleemailmessage createTemplatedEmailMessage(Id to, Id templateId, Id relatedToId){
        
        Messaging.SingleEmailMessage mail = buildTemplatedEmailMessage(to, templateId, relatedToId, false, '', false, false);
        
        return mail;
    }
    
    private static Messaging.SingleEmailMessage buildTemplatedEmailMessage(Id to, Id templateId, Id relatedToId, Boolean saveActivity, String replyTo, Boolean bccSender, Boolean useSignature){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(to);
        mail.setSaveAsActivity(saveActivity);
        mail.setWhatId(relatedToId);
        //mail.setReplyTo(String.isEmpty(replyTo) ? 'donotreply@integratelecom.com' : replyTo);
        mail.setBccSender(bccSender);
        mail.setUseSignature(useSignature);
        
        return mail;
    }
    
    private static Messaging.Singleemailmessage buildEmailMessage(String[] cc, String subject, String body, Boolean isHtml, String replyTo){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setReplyTo(string.IsEmpty(replyTo) ? 'donotreply@integratelecom.com' : replyTo);

        mail.setCcAddresses(cc);
        mail.setSubject(subject);

        if(isHtml)
            mail.setHtmlBody(body);
        else
            mail.setPlainTextBody(body);

        return mail;
    }
    
    public static Boolean sendEmails(Messaging.SingleEmailMessage[] emails){
        try{
            Messaging.sendEmail(emails);
        }
        catch (Exception e){
            system.debug('Unable to send email(s): ' + e.getMessage());
            return false;
        }
        return true;
    }
    
    /**************************************************************************/
    /*      Utility to remove matches of regular expression                   */
    /**************************************************************************/
    
     public static String removeAllByCustomPattern(String fieldValue, String custPattern){
        
        if(string.IsEmpty(fieldValue)) return '';
        
        pattern ipattern = pattern.compile(custPattern);
        matcher imatcher = ipattern.matcher(fieldValue);

        return imatcher.replaceAll('');
     }
     
    /**************************************************************************/
    /*      Validate string is a salesforce ID                                */
    /**************************************************************************/
    
     public static Boolean isValidId(String s) 
     {    
        Id validId = null;    
        try {       
            validId = s;       
            return true;     
            } 
        catch (Exception ex){        
            return false;    
            }
     }

    /**************************************************************************/
    /*      get salesforce ID from string by position                         */
    /**************************************************************************/
 
    public static ID captureIdByPostion(String s, Integer position){
        if(s == null) return null;
        
        Matcher m = Pattern.compile('\\d{2}[a-zA-Z0-9]{13,16}').matcher(s);

        String[] items = new String[position+10];
        
        Integer count = 0;
        while(m.find()) {
            Integer startIdx = m.start();
            Integer endIdx = m.end();
            String retVal = s.substring(startIdx, endIdx);
            
            if(ApexUtils.isValidId(retVal)){    
                items[count] = retVal; 
                count++;
            }
        }
        
        try{
            return (ID)items[position];
        }
        catch (Exception ex){
            system.debug('String does not contain ID. -  String: ' + s + ' Exception Details: ' + ex);
            return null;
        }
    }
    
    /**************************************************************************/
    /*                              Trigger methods                           */
    /**************************************************************************/
    private static Map<String, Map<Boolean, Integer>> triggerCounts;    //{ SObject: { isBefore: { Count } } }, counts will equal one another when not in the trigger
    public static Boolean executeTriggerMethods(String sObjectName, Boolean isBefore, Boolean isDelete){
        
        //Always execute delete actions
        
        if(isDelete) return true;
        
        if(triggerCounts == null)
            triggerCounts = new Map<String, Map<Boolean, Integer>>();
        if(triggerCounts.get(sObjectName) == null)
            triggerCounts.put(sObjectName, new Map<Boolean, Integer>{true=>0, false=>0});
            
        Boolean execute;
        if(isBefore){
            execute = triggerCounts.get(sObjectName).get(true) == triggerCounts.get(sObjectName).get(false);
            triggerCounts.get(sObjectName).put(true, triggerCounts.get(sObjectName).get(true) + 1);
        }
        else{
            execute = triggerCounts.get(sObjectName).get(true) == triggerCounts.get(sObjectName).get(false)+1;
            if(!execute) triggerCounts.get(sObjectName).put(false, triggerCounts.get(sObjectName).get(false) + 1);
        }
        
        //system.debug((isBefore ? 'before ' : 'after ') + execute + ' ' + triggerCounts.get(sObjectName).get(true)+':'+triggerCounts.get(sObjectName).get(false));
        
        return execute;
    }
    
    public static void afterTriggerComplete(String sObjectName, Boolean isDelete){
        if(!isDelete){
            triggerCounts.get(sObjectName).put(true, 0);
            triggerCounts.get(sObjectName).put(false, 0);
        }
    }
    
    public static Boolean inTrigger(String sObjectName){
        return triggerCounts != null && triggerCounts.get(sObjectName) != null && triggerCounts.get(sObjectName).get(true) != triggerCounts.get(sObjectName).get(false);
    }
    
    /**************************************************************************/
    /*                              Copying methods                           */
    /**************************************************************************/
    
    public static sObject deepCopyFields(sObjectType objType, sObject copyFrom, sObject copyTo, Set<String> ignoreFields){
        return deepCopyFields(objType, copyFrom, copyTo, ignoreFields, false);
    }
    
    public static sObject deepCopyFields(sObjectType objType, sObject copyFrom, sObject copyTo, Set<String> ignoreFields, Boolean defaultNulls){
        if(ignoreFields == null)
            ignoreFields = new Set<String>();
        
        Set<String> fields = new Set<String>();
        Set<String> defaultFields = new Set<String>();      
        Map<String, Schema.Describefieldresult> fs = SchemaUtils.RetrieveFullObjectFieldDescribeMap(objType);
        for(String key : fs.keyset()) {
            Schema.Describefieldresult dfr = fs.get(key);
            String name = dfr.getName();
            if(dfr.isCalculated() || dfr.isAutoNumber() || !(dfr.isCustom() || dfr.isUpdateable()) /*|| !dfr.isCreateable()*/ || ignoreFields.contains(name)) continue;
            if(defaultNulls && dfr.isDefaultedOnCreate()) defaultFields.add(name);
            fields.add(name);
        }
        
        return copyFieldsTo(copyFrom, copyTo, fields, defaultFields);
    }
    
    public static SObject copyFieldsTo(sObject copyFrom, sObject copyTo, Set<String> fields){
        for(String f : fields)
            copyTo.put(f, copyFrom.get(f));
        
        return copyTo;
    }
    
    public static SObject copyFieldsTo(SObject copyFrom, SObject copyTo, Set<String> fields, Set<String> defaultFields){
        for(String f : fields){
            Object val = copyFrom.get(f);
            if(!defaultFields.contains(f) || val != null)
                copyTo.put(f, val);
        }
        return copyTo;
        
    }
    
    /**************************************************************************/
    /*                              Sorting methods                           */
    /**************************************************************************/
    
    public static List<object> sortValues(List<object> values, Boolean ascending){
        values.sort();
        
        if(!ascending){
            List<object> reversed = new List<object>();
            for(Integer i=values.size()-1; i>=0; i--)
                reversed.add(values.get(i));
            values = reversed;
        }
        
        return values;
    }
    
    public static List<sObject> sortByComparableField(List<sObject> unsortedList, String fieldName, Boolean ascending, Boolean nullsFirst){
        Map<object, List<sObject>> valMap = new Map<object, List<sObject>>();
        List<sObject> nullVals = new List<sObject>();
        
        for(sObject obj : unsortedList){
            object val = (object)obj.get(fieldName);
            if(val == null)
                nullVals.add(obj);
            else{
                List<sObject> l = (valMap.get(val) != null) ? valMap.get(val) : new List<sObject>();
                l.add(obj);
                valMap.put(val, l);
            }
        }
        
        List<sObject> retval = new List<sObject>();
        for(object val : sortValues(new List<object>(valMap.keyset()), ascending))
            retval.addAll(valMap.get(val));
        
        if(nullsFirst){
            nullVals.addAll(retval);
            retval = nullVals;
        }
        else
            retval.addAll(nullVals);
        
        return retval;
    }
    
    public virtual class SortableClassConfig{
        public String sortObject {get; set;}
        public String sortField {get; set;}
        public Boolean sortAscending {get; set;}
        
        //Secondary SOQL only sorting
        public String soqlSortField2 {get; set;}
        public Boolean soqlSortAscending2 {get; set;}
        public String filterName {get; set;}
        
        public SortableClassConfig(){}
        public SortableClassConfig(String sortObject, String sortField, Boolean sortAscending){
            setup(sortObject, sortField, sortAscending);
        }
        
        public void setup(String sortObject, String sortField, Boolean sortAscending){
            this.sortObject = sortObject;
            this.sortField = sortField;
            this.sortAscending = sortAscending;
        }
        
        public void changeSort(String sortObject, String sortField){
            this.sortAscending = (this.sortObject == sortObject && this.sortField == sortField) ? !sortAscending : true;
            this.sortObject = sortObject;
            this.sortField = sortField;
        }
    }
        
    private static SortableClassConfig currentConfig { get; set; }
    
    public static void Sort(List<SortableClass> l, SortableClassConfig config){
        currentConfig = config;
        l.sort();
    }
    
    public static void SortBy(List<SortableClass> l, List<String> sortBy){
        currentConfig = new ApexUtils.SortableClassConfig('', '', true);
        for(String s : sortBy){
            currentConfig.sortField = s;
            l.sort();
        }
    }
    
    public virtual class SortableClass implements Comparable {
        
        public Map<String, sObject> sObjectMap { get; set; }
        
        public virtual object getFieldImp(String fName) {
            object fVal = null;
            if(currentConfig != null && sObjectMap != null && sObjectMap.get(currentConfig.sortObject) != null){
                sObject obj = sObjectMap.get(currentConfig.sortObject);
                while(obj != null && fName.contains('.')){
                    List<String> split = fName.split('.');
                    if(split.size() == 0 || split[0].length() == 0)
                        return null;
                    
                    obj = obj.getsObject(split[0]);
                    fName = fName.substring(split[0].length() + 1);
                }
                
                if(obj != null && fName.length() > 0)
                    fVal = obj.get(fName);
            }
            return fVal;
        }
        
        private object getField(String fName){
            object val = getFieldImp(fName);
            return (val != null && (val instanceof String)) ? toLower((string)val) : val;
        }
        
        public Integer compareTo(Object compareTo){
            SortableClass ct = (SortableClass)compareTo;
            object f1 = getField(currentConfig.sortField);
            object f2 = ct.getField(currentConfig.sortField);
            
            //If equal return 0 else sort and return based on first result and ascending flag
            return (f1 == f2) ? 0 : (sortValues(new List<object>{f1, f2}, currentConfig.sortAscending)[0] == f1) ? -1 : 1;
        }
        
        private String toLower(String s){
            return s != null ? s.toLowercase() : null;
        }
    }
    
    public static Boolean buildWhereClause(List<String> whereClause, Boolean add, String whereClausePart){
        if(add)
            whereClause.add(whereClausePart);
        return add;
    }
    
    /**************************************************************************/
    /*                              date methods                              */
    /**************************************************************************/
    
    private static List<Holiday> allHolidaysList;
    public static List<Holiday> AllHolidays {
        get{
            if (allHolidaysList == null)
                allHolidaysList = [SELECT Id, ActivityDate, RecurrenceStartDate, StartTimeInMinutes, EndTimeInMinutes,RecurrenceInterval,RecurrenceEndDateOnly FROM Holiday];
            return allHolidaysList;
        }
        set;
    }
    private static Set<Date> holidayRecDatesSet;
    public static Set<Date>HolidayRecDates{
        get{
            if(holidayRecDatesSet == null){
                holidayRecDatesSet = new Set<Date>();
                for (Holiday h : AllHolidays)
                    holidayRecDatesSet.add(h.RecurrenceStartDate);
            }
            return holidayRecDatesSet;
        }
    }
    public static Boolean isHoliday(){
        return HolidayRecDates.contains(Date.today());
    }
    public static Boolean isHoliday(Date day){
        return HolidayRecDates.contains(day);
    }
    
    public static Boolean isSandbox() {
      return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }    
    /* TestUtils.ITestableClass methods */
    public TestUtils.TestClass getTestClass(){ return new Test_ApexUtils(); }
}