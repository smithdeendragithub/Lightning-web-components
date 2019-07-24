/*
* @Author: Smithdeendra A P
* @Created Date: 12-July-2019
* @Modified Date: 12-July-2019
* @TestClass: lgt_DataFactory_Test
* Version     JIRA                  Author                        Comments
* 1.0         SEAL-2907            Smithdeendra A P              Initial Comments.
* 1.1         SEAL-2907            Smithdeendra A P              added new wrapper class wrapFieldSet and new variable fieldSetJSON.
*/
public with sharing class lgt_ManageFeaturesScheduleController implements TestUtils.ITestableClass{
    
    @AuraEnabled public Technical_Information__c currentTI {get;set;}
    
   // @AuraEnabled List<Schema.FieldSetMember> fieldsetList {get;set;}
    @AuraEnabled public List<wrapFieldSet> fieldsetList {get;set;}
    @AuraEnabled public String DebugString {get;set;}
    @AuraEnabled public FeaturesScheduleValidations validations; 
    @AuraEnabled public List<OLI__c> products;
    @AuraEnabled public List<OLI__c> features;
    @AuraEnabled public Map<Id, List<FeaturesScheduleValidations.wrapFeatureContent> >packageFeatures;
    @AuraEnabled public Map<Id, Decimal> oliCount = new Map<Id, Decimal>();
    //This one will decrease with each line we add
    @AuraEnabled public Map<Id, Decimal> oliQty = new Map<Id, Decimal>();
    //This one is needed to get the right qty and compare for preselect
    @AuraEnabled public List<CN_Feature__c> deleteFeatures = new List<CN_Feature__c>();
    @AuraEnabled public List<OLI__c> existingPackageContentOLIs = new List<OLI__c>();
    //If I created this OLI solely for the features within a package, add it to this list.
    @AuraEnabled public List<OLI__c> insertedPackageContentOLIs = new List<OLI__c>();
    //If I created this OLI solely for the features within a package, but the validation fails, then get rid of it
    @AuraEnabled public String hostedVoice{get;set;}
    @AuraEnabled public Boolean firstPass = false;
    //If it's the first time in this screen
    @AuraEnabled public Decimal cnLength = 0;
    @AuraEnabled public Boolean hasOrphanOLIs{get;set;}
    @AuraEnabled public List<wrapFeatureTitle> displayFeatures {get;set;}
    @AuraEnabled public Map<String,String> lines{get;set;}
    @AuraEnabled public Map<String,String> callBlocklines {get;set;}
    @AuraEnabled public List<wrapNumber> TelephoneNumbers {get;set;}
    @AuraEnabled public Map<Id, List<CN_Feature__c> >TelephoneFeatures {get;set;}
    @AuraEnabled public String myDebugString {get;set;}
    @AuraEnabled public String warnings {get;set;}
    @AuraEnabled public Map<String,String> getLineUseOptions(){
        Map<String,String> options = new Map<String,String>();
        List<Schema.PicklistEntry> picklistEntries = Schema.sObjectType.CN__c.fields.Line_Use__c.getPicklistValues();
        for (Schema.PicklistEntry picklistEntry : picklistEntries) {
            options.put(picklistEntry.getLabel(), picklistEntry.getValue());
        }
        return options;
    }
    @AuraEnabled public Map<String,Map<String,CN_Feature__c> >cncToCnCFeatures;
    @AuraEnabled public Map<String,CN_Feature__c> oppnameToCnFeature;
    @AuraEnabled public Map<String,List<CN_Feature__c> >oppnameToCnFeaturelst;
    @AuraEnabled public String fieldFocusId{get;set;}
    @AuraEnabled public Id cnRemoveId {get;set;}
    public void messageDisplay(String Msg) {
        ApexPages.Message m = new ApexPages.Message(ApexPages.Severity.WARNING, Msg);
        ApexPages.addMessage(m);
    }
    public lgt_ManageFeaturesScheduleController(){}
    
    public lgt_ManageFeaturesScheduleController(Id tiRecordId) {
        List<Technical_Information__c> tempTIObjList = [select Id,Opportunity_Site__c,Opportunity_Site__r.Order__r.Opportunity__c from Technical_Information__c where id = :tiRecordId];
        if(!tempTIObjList.isEmpty()){
            this.fieldFocusId = 'nothing yet';
            this.currentTI = tempTIObjList[0];//(Technical_Information__c)stdController.getRecord();
            this.DebugString = this.currentTI.id;
            this.fieldsetList = new List<wrapFieldSet>();
            this.initScreen();
            
        }
        else{
            throw new SObjectException('Not a valid technical information record id');
        }
    }
    
    public void initScreen() {
        System.debug('MNK ManageFeatureSceduleController initScreen start');
        for(Schema.FieldSetMember fsm : Schema.SObjectType.CN__c.fieldSets.CN.Fields)
            this.fieldsetList.add(new wrapFieldSet(fsm));
           //this.fieldsetList =  Schema.SObjectType.CN__c.fieldSets.CN.Fields;
        this.DebugString = this.currentTI.id;
        this.TelephoneFeatures = new Map<Id, List<CN_Feature__c> >();
        this.TelephoneNumbers = new List<wrapNumber>();
        this.displayFeatures = new List<wrapFeatureTitle>();
        this.lines = new Map<String,String>();
        this.callBlocklines = new Map<String,String>();
        this.warnings = '';
        this.myDebugString = '';
        this.hostedVoice = '';
        Integer i = 0;
        //First the information I need to validate against
        System.debug('MNK ManageFeatureSceduleController initScreen create FeatureScheduleValidations');
        this.validations = new FeaturesScheduleValidations(this.currentTI.Opportunity_Site__c);
        System.debug('MNK ManageFeatureSceduleController initScreen get products');
        this.products = this.validations.products;
        System.debug('MNK ManageFeatureSceduleController initScreen products.size() ' + products.size());
        System.debug('MNK ManageFeatureSceduleController initScreen get features');
        this.features = this.validations.features;
        System.debug('MNK ManageFeatureSceduleController initScreen features.size() ' + features.size());
        System.debug('MNK ManageFeatureSceduleController initScreen get package features');
        this.packageFeatures = this.validations.packageFeatures;
        System.debug('MNK ManageFeatureSceduleController initScreen packageFeatures.size() ' + packageFeatures.size());
        this.oppnameToCnFeaturelst = new Map<String,List<CN_Feature__c> >();
        //No longer valid.....
        this.validations.hasOrphanOLIs = false;
        this.hasOrphanOLIs = this.validations.hasOrphanOLIs;
        this.packageItemToCncFeatureToInsert = new Map<String,List<CN_Feature__c> >();
        if (this.hasOrphanOLIs) {
            this.warnings = 'This Screen refers to Product Pricing records that are expired or no longer exist. This screen will be read only until the Opportunity is fixed.';
        }
        // try{
        //Initialize my Maps and Create the options for the dropdowns
        //this.lines.put(new SelectOption('', '<Select>'));
        for (OLI__c oli :this.products) {
            //Need to check for hosted voice products and seperate track them - 08292012
            if (oli.PP_Sales_Product__c.contains('Hosted Voice')) {
                this.hostedVoice = 'Hosted Voice';
            }
            else {
                this.hostedVoice = 'Not Hosted Voice';
            }
            this.oliCount.put(oli.id, oli.Qty__C);
            this.oliQty.put(oli.id, oli.Qty__C);
            this.lines.put(oli.Id, oli.PP_Sales_Rate_Plan_Description__c + ' ('+ oli.Qty__C + ')');
        }
        //Now get all the CNs that have already been populated.
        String query = '';
        String objectFields = '';
        objectFields = SchemaUtils.RetrieveFullObjectFields(CN__c.sObjectType);
        query = 'Select ';
        query +=objectFields + ',';
        query +='Opportunity_Line_Item__r.Qty__c, '+ 'Opportunity_Line_Item__r.PP_Package_Feature__c,'+ 'Opportunity_Line_Item__r.OpportunityLocationConfiguration__c, '+ 'Opportunity_Line_Item__r.PP_Sales_Rate_Plan_Description__c, '+ 'Opportunity_Line_Item__r.PP_Sales_Product__c, '+ 'Opportunity_Line_Item__r.PP_Package__c, '+ 'Opportunity_Line_Item__r.SPC_Sales_Product_Component_Id__c, '+ 'Opportunity_Line_Item__r.SPC_Component_Id__c, '+ '(Select Id,  '+ '       Name,  '+ '       Opportunity_Line_Item__c, '+ '       Additional_Info__c, '+ '       Opportunity_Line_Item__r.PP_SalesProductRatePlanExternalID__c, '+ '       Opportunity_Line_Item__r.PP_Package_Feature__c '+ '       from CN_Features__r) '+ 'from   CN__c '+ 'where  Opportunity_Location__c = \''+ this.currentTI.Opportunity_Site__c + '\' '+ 'order by Name';
        List<CN__c> lstCN = Database.query(query);
        this.cncToCnCFeatures = new Map<String,Map<String,CN_Feature__c> >();
        for (CN__c cnc :lstCN) {
            if (cnc.CN_Features__r.size()>0) {
                for (CN_Feature__c cncfeatures :cnc.CN_Features__r) {
                    if (this.cncToCnCFeatures.containsKey(cnc.Name)) {
                        Map<String,CN_Feature__c> tempMap = this.cncToCnCFeatures.get(cnc.Name);
                        tempMap.put(cncfeatures.name, cncfeatures);
                        this.cncToCnCFeatures.put(cnc.Name, tempMap);
                    }
                    else {
                        Map<String,CN_Feature__c> tempMap = new Map<String,CN_Feature__c>();
                        tempMap.put(cncfeatures.name, cncfeatures);
                        this.cncToCnCFeatures.put(cnc.Name, tempMap);
                    }
                }
            }
        }
        try {
           // this.callBlocklines = createCallBlockSelectOptions();
        //    createCallBlockSelectOptions();
           for (Schema.PicklistEntry picklistEntry : Schema.sObjectType.CN__c.fields.Call_Blocking__c.getPicklistValues()) {
            this.callBlocklines.put(picklistEntry.getLabel(), picklistEntry.getValue());
        }
        }
        catch (Exception e) {
            messageDisplay(e.getMessage());
            System.debug(e);
        }
        integer LineNo = 0;
        for (CN__c cn :lstCN) {
            LineNo +=1;
            wrapNumber tel = new wrapNumber(cn);
            tel.isTotalLine = false;
            if (LineNo> this.validations.totalLines) {
                //If I have orphan OLIs, I can't let it delete
                tel.deletable = true && (!this.hasOrphanOLIs);
            }
            else {
                tel.deletable = false;
            }
            //Decrease the map that contains the count
            //I do this to be able to autoselect the lines upon creation
            decreaseMap(cn.Opportunity_Line_Item__c);
            if (oliCount.containsKey(cn.Opportunity_Line_Item__c)) {
                tel.changeable = false;
            }
            else {
                //If I have OrphanOLIs I can't let it change
                tel.changeable = true&&(!hasOrphanOLIs);
            }
            this.TelephoneNumbers.add(tel);
        }
        if (this.TelephoneNumbers.size()== 0) {
            firstPass = true;
        }
        //Get the CNs in there for all the needed lines
        if (this.validations.totalLines> this.TelephoneNumbers.size()) {
            Decimal missingLines = this.validations.totalLines - this.TelephoneNumbers.size();
            Decimal initialLineNumber = this.TelephoneNumbers.size();
            for (i = 0;
                 i <missingLines;
                 i ++) {
                     CN__c cn = new CN__c();
                     cnLength = initialLineNumber + i + 1;
                     if (cnLength <10) {
                         cn.Name = 'TN 000'+ (initialLineNumber + i + 1);
                     }
                     else if (cnLength <100) {
                         cn.Name = 'TN 00'+ (initialLineNumber + i + 1);
                     }
                     else if (cnLength <1000) {
                         cn.Name = 'TN 0'+ (initialLineNumber + i + 1);
                     }
                     else {
                         cn.Name = 'TN '+ (initialLineNumber + i + 1);
                     }
                     cn.Opportunity_Location__c = this.currentTI.Opportunity_Site__c;
                     //Find the right opportunity Line item to add
                     Id selectedOLI = findNextOpenOLI();
                     if (selectedOLI != null) {
                         cn.Opportunity_Line_Item__c = selectedOLI;
                         decreaseMap(selectedOLI);
                     }
                     insert cn;
                     wrapNumber tel = new wrapNumber(cn);
                     tel.isTotalLine = false;
                     tel.deletable = false;
                     if (this.oliCount.containsKey(cn.Opportunity_Line_Item__c)) {
                         tel.changeable = false;
                     }
                     else {
                         tel.changeable = true;
                     }
                     this.TelephoneNumbers.Add(tel);
                 }
        }
        else if (this.validations.totalLines <TelephoneNumbers.size()) {
            messageDisplay('The number of lines in the current active solution is less than the amount in the Database. Please delete the excess lines before saving.');
        }
        //Add a "Totals" line so I can select all checkboxes at once
        wrapNumber telTotal = new wrapNumber();
        telTotal.isTotalLine = true;
        telTotal.deletable = false;
        this.TelephoneNumbers.add(telTotal);
        //Put all the features
        System.debug('MNK ManageFeaturesScheduleController initScreen put all the features');
        for (OLI__c oli :this.features) {
            //Only do the titles for those who aren't part of the "Package Feature"
            //The features will have to be added in the next step, when I find values for the checkboxes
            if (!oli.PP_Package_Feature__c) {
                addToTitles(oli);
                //Add each feature as a feature in the list
                for (wrapNumber tel :this.TelephoneNumbers) {
                    addToColumnFeatures(tel, oli);
                }
            }
            else {
                //If I created this OLI solely for the features within a package, add it to this list.
                this.existingPackageContentOLIs.add(oli);
            }
        }
        
        //Now go through the collection, and add the right values based on the features
        for (wrapNumber tel :this.TelephoneNumbers) {
            try {
                system.debug('checkPoint1 => ' + JSON.serialize(tel));
                if(null != tel.cn){
                    for (CN_Feature__C cnfeat :tel.cn.CN_Features__r) {
                        //For each existing feature find the corresponding column (added before)
                        system.debug('checkPoint2 => '+JSON.serialize(cnfeat));
                        wrapFeature feat = findFeature(cnfeat, tel.features);
                        
                        if (feat != null) {
                            //If I found it, set it up properly
                            feat.feature = cnfeat;
                            feat.selected = true;
                            system.debug('checkPoint3');
                            feat.additionalInformation = cnfeat.Additional_Info__c;
                            //If found something but I didn't have an OLI, this means that the feature 
                            //is part of a package. We need to tell the feature which OLI it was associated with
                            if (feat.oli == null) {
                                feat.oli = cnfeat.Opportunity_Line_Item__r;
                            }
                        }
                        else {
                            //If I can't find the column, then it no longer exists and the CNFeatures must be deleted from when saving
                            this.deleteFeatures.add(cnfeat);
                        }
                    }
                }
            }
            catch (Exception e) {
                //messageDisplay(e.getMessage() + ' ' + tel.features);
                System.debug(e);
            }
        }
        Set <Id> allexitingOliId = new Set <ID>();
        set <String> existingname = new Set <String>();
        for (OLI__c ol :existingPackageContentOLIs) {
            allexitingOliId.add(ol.id);
            existingname.add(ol.Dq__c);
        }
        this.oppnameToCnFeature = new Map<String,CN_Feature__c>();
        //Setting a map from itemname to cnc package from existing oli...
        for (OLI__c ol :[Select id,DQ__C,(Select id,name,Additional_Info__c,CN__c from CN_Features__r) from OLI__c where id IN:allexitingOliId]) {
            for (CN_Feature__c cnc :ol.CN_Features__r) {
                this.oppnameToCnFeature.put(ol.DQ__c, cnc);
                if (!this.oppnameToCnFeaturelst.containskey(ol.DQ__c))
					this.oppnameToCnFeaturelst.put(ol.DQ__c, new List<CN_Feature__c>{cnc});
                else {
                    this.oppnameToCnFeaturelst.get(ol.DQ__c).add(cnc);
                }
            }
        }
        //Find the existing package and set the selected
        for (wrapNumber tel :this.TelephoneNumbers) {
            Set <String> allcn = new Set <String>();
            for (wrapFeature feature :tel.features) {
                if (feature.isPartOfPackage) {
                    if (this.oppnameToCnFeature.containskey(feature.name)) {
                        List<CN_Feature__c> cnclst = this.oppnameToCnFeaturelst.get(feature.name);
                        // if(cnc!=NULL)
                        //{
                        for (CN_Feature__c cnc :cnclst) {
                            if (tel.cn != NULL &&tel.cn.id != NUll &&tel.cn.id == cnc.cn__C) {
                                if (feature.additionalInformationPrompt != '')feature.additionalInformation = cnc.Additional_Info__c;
                                feature.selected = true;
                            }
                        }
                        //}
                    }
                }
            }
        }
        //Disable all the checkboxes
        //Checkbox  disability is controlled from here .....
        if (hostedVoice != 'Hosted Voice') {
            preselectCheckboxes();
            hostedVoice = 'Not HV';
        }
    }
    public PageReference updateFeatureAvailability() {
        System.debug('MNK ManageFeatureScheduleController updateFeatureAvailability');
        for (wrapNumber tel :TelephoneNumbers) {
            if (!tel.isTotalLine) {
                if (tel.cn.Opportunity_Line_Item__c != null) {
                    //Always find the proper SP based on the selection just made (the retrieved one could be old)
                    String salesProduct = findSalesProduct(tel.cn.Opportunity_Line_Item__c);
                    //If the line has been assigned, check all its features for the possibility  
                    for (wrapFeature feat :tel.features) {
                        if ((feat.salesProduct != salesProduct)&&(feat.salesProduct != '_ALL_')) {
                            feat.additionalInformation = '';
                            feat.selected = false;
                            feat.disabled = true;
                        }
                        else {
                            //If I have Orphan OLIs disable regardless
                            feat.disabled = false||hasOrphanOLIs;
                        }
                    }
                }
                else {
                    for (wrapFeature feat :tel.features) {
                        feat.additionalInformation = '';
                        feat.selected = false;
                        feat.disabled = true;
                    }
                }
            }
        }
        return null;
    }
    @AuraEnabled public Map<String,CN__c> nameToCn = new Map<String,CN__c>();
    public List<CN_Feature__c> parentfeature(List<OLI__c> alloliinserted) {
        System.debug('MNK ManageFeatureScheduleController parentfeature');
        Set <String> olid = new Set <String>();
        Set <String> allcnid = new Set <String>();
        Set <String> parentName = new Set <String>();
        Map<String,CN_Feature__c> nameToCNFeature = new Map<String,CN_Feature__c>();
        List<CN_Feature__c> allcnfeature = new List<CN_Feature__c>();
        for (OLI__C o :alloliinserted) {
            olid.add(o.id);
        }
        Map<String,List<CN_Feature__c> >oppnameToCncFeature = new Map<String,List<CN_Feature__c> >();
        for (OLI__c ol :[Select id,DQ__c, (Select Name, CN__c,cn__r.name,Opportunity_Line_Item__c,
                                           Opportunity_Line_Item__r.name From CN_Features__r) 
                         from OLI__c  where id=:olid]) {
                             oppnameToCncFeature.put(ol.Dq__C, ol.CN_Features__r);
                         }
        for (OLI__C oli :alloliinserted) {
            List<CN_Feature__c> lstcnfeatures = oppnameToCncFeature.get(oli.DQ__C);
            Set <String> cnid = new Set <String>();
            Map<String,String> cnidToName = new Map<String,String>();
            for (CN_Feature__c cnf :lstcnfeatures) {
                cnid.add(cnf.CN__c);
                cnidToName.put(cnf.CN__c, cnf.cn__r.name);
            }
            for (String str :cnid) {
                CN_Feature__c cnc = new CN_Feature__c();
                cnc.Opportunity_Line_Item__c = oli.Parent_Opportunity_Line_Item__c;
                cnc.CN__c = str;
                cnc.name = cnidToName.get(str)+ '-'+ oli.ParentName__c;
                //Else we are not creating cncfor parent as it already existed
                nameToCNFeature.put(cnc.name, cnc);
                allcnid.add(str);
            }
        }
        for (CN__c cn :[Select id, (Select Name, CN__c From CN_Features__r) From CN__c where id in :allcnid]) {
            if (cn.CN_Features__r.size()>0) {
                for (CN_Feature__c cnc :cn.CN_Features__r) {
                    if (nameToCNFeature.containskey(cnc.name))nameToCNFeature.remove(cnc.name);
                }
            }
        }
        if (!nameToCNFeature.isEmpty()) {
            for (String s :nameToCNFeature.keyset()) {
                allcnfeature.add(nameToCNFeature.get(s));
            }
        }
        if (allcnfeature.size()== 0)return null;
        else return allcnfeature;
    }
    Set <String> oliToupdateId = new Set <String>();
    private CN_Feature__c creatCncFeature(wrapFeature feat, CN__c cn) {
        System.debug('MNK ManageFeatureScheduleController createCnCFeature');
        System.debug('KIT - feat: ' + feat);
        System.debug('KIT - CN__c: ' + cn);
        CN_Feature__c cncfeature = new CN_Feature__c();
        cncfeature.CN__c = cn.id;
        cncfeature.name = cn.name + '-'+ feat.name;
        cncfeature.Opportunity_Line_Item__c = feat.oli.id;
        List<CN_Feature__c> cnfeaturelst = oppnameToCnFeaturelst.get(feat.name);
        if(cnfeaturelst == null) cnfeaturelst = new List<CN_Feature__c>();
        boolean existed = false;
        for (OLI__c ol :[Select Id, (Select Name, CN__c From CN_Features__r) From OLI__c Where id=:feat.oli.id]) {
            if (ol.CN_Features__r.size()!= 0) {
                for (CN_Feature__c existedfeature :ol.CN_Features__r) {
                    if (existedfeature.name == cncfeature.name)existed = true;
                }
            }
        }
        for(CN_Feature__c existingFeature : cnfeaturelst){
            if(existingFeature.name == cncfeature.Name)existed = true;
        }
        if (!existed){
            cnfeaturelst.add(cncfeature);
            oppnameToCnFeaturelst.put(feat.name, cnfeaturelst);
            return cncfeature;
        }
        else return null;
    }
    public PageReference saveOnly() {
        List<CN__c> updateNumbers = new List<CN__c>();
        List<CN_Feature__c> updateFeatures = new List<CN_Feature__c>();
        List<CN_Feature__c> insertFeatures = new List<CN_Feature__c>();
        List<OLI__c> updateOLIs = new List<OLI__c>();
        List<OLI__c> deleteOLIs = new List<OLI__c>();
        List<CN_Feature__c> deleteFeatures = new List<CN_Feature__c>();
        //If due to validation rule if oli is inserted have to revert back
        List<OLI__c> deleteoli = new List<OLI__c>();
        List<CN_Feature__c> insertNonPackage = new List<CN_Feature__c>();
        wrapNumber totalsLine;
        Integer i = 0;
        for (wrapNumber tel :TelephoneNumbers) {
            if (tel.isTotalLine) {
                totalsLine = tel;
                TelephoneNumbers.remove(i);
                break ;
            }
            i +=1;
        }
        //First zero out all the existing OLIs. At the end of the process, we'll delete those with Qty = 0
        zeroOutPackageContentOLI();
        //Go through everything once because I have to add all the OLIs (for feature packages) first. Then I can do my updates
        Set <String> allcnid = new Set <String>();
        for (wrapNumber tel :TelephoneNumbers) {
            if (tel.cn != NULL) {
                updateNumbers.add(tel.cn);
                allcnid.add(tel.cn.id);
            }
            for (wrapFeature feat :tel.features) {
                if (feat != NULL) {
                    if (!feat.ispartofpackage) {
                        if (feat.selected) {
                            //insertNonPackage
                            CN_Feature__c cnc = creatCncFeature(feat, tel.cn);
                            if (cnc != null)insertNonPackage.add(cnc);
                        }
                    }
                    if (feat.feature == null &&(feat.selected == true||feat.additionalInformation != '')) {
                        if (feat.isPartOfPackage) {
                            if (tel.cn != NULL) {
                                nameToCn.put(feat.name, tel.cn);
                                savePackageContentOLI(feat);
                            }
                        }
                    }
                    else if (feat.feature != null &&(feat.selected == true||feat.additionalInformation != '')) {
                        if (feat.isPartOfPackage) {
                            if (tel.cn != NULL) {
                                nameToCn.put(feat.name, tel.cn);
                                savePackageContentOLI(feat);
                            }
                        }
                    }
                }
            }
        }
        Set <OLI__c> removeduplicate = new Set <OLI__c>();
        removeduplicate.addAll(insertedPackageContentOLIs);
        insertedPackageContentOLIs = new List<OLI__c>();
        insertedPackageContentOLIs.addAll(removeduplicate);
        //Insert or upsert opporttunity line item for package content...F
        if (insertedPackageContentOLIs.size()>0) {
            //insertedPackageContentOLIs = GlobalUtilities.updateOLIswithProductPricingInformation(insertedPackageContentOLIs);
            //We will be getting the value from api ..So we need to OpportunityLocation_Configuration__
            for (OLI__c oli :insertedPackageContentOLIs) {
                deleteoli.add(oli);
            }
            upsert insertedPackageContentOLIs;
        }
        
        Map<String,Set<Id>> cnFeatureMap = new Map<String,Set<Id>>();
        for (CN__C cn :[Select Name, (Select id,Name,Opportunity_Line_Item__c From CN_Features__r) From CN__c Where ID IN:allcnid]) {
            for (CN_Feature__c cnf :cn.CN_Features__r) {
                if(cnFeatureMap.containsKey(cn.Id)){
                    Set<Id> cnfs = cnFeatureMap.get(cn.Id);
                    cnfs.add(cnf.Opportunity_Line_Item__c);
                    cnFeatureMap.put(cn.Id,cnfs);
                }
                else{
                    cnFeatureMap.put(cn.Id,new Set<Id>{cnf.Opportunity_Line_Item__c});
                }
                
            }
        }
        
        
        //Now after inserting line item  new features has to be insert
        //Only insert those that don't have the same OLI already on them
        for (OLI__c oli :insertedPackageContentOLIs) {
            if (packageItemToCncFeatureToInsert.containskey(oli.Dq__C)) {
                List<CN_Feature__c> cnfeat = packageItemToCncFeatureToInsert.get(oli.Dq__C);
                for (CN_Feature__c feat :cnfeat) {
                    feat.Opportunity_Line_Item__c = oli.id;
                    Set<Id> olisOnFeature = new Set<Id>();
                    
                    if(cnFeatureMap.get(feat.cn__c) != null){
                        olisOnFeature = cnFeatureMap.get(feat.cn__c);
                    }
                    
                    if(!olisOnFeature.contains(oli.Id)){
                        insertFeatures.add(feat);
                    }
                }
            }
        }
        
        //No need to get oli....
        //If parentcnc features is not existed need to insert parent features
        if (!insertFeatures.isEmpty()) {
            System.debug('KIT - Features inserted: ' + insertFeatures);
            upsert insertFeatures;
        }
        List<CN_Feature__c> parentcnfeature = parentfeature(insertedPackageContentOLIs);
        if (parentcnfeature != NULL &&!parentcnfeature.isEmpty()){
            List<CN_Feature__c> parentsToInsert = new List<CN_Feature__c>();
            for (CN_Feature__c feat :parentcnfeature) {
                Set<Id> olisOnFeature = new Set<Id>();
                
                if(cnFeatureMap.get(feat.cn__c) != null){
                    olisOnFeature = cnFeatureMap.get(feat.cn__c);
                }
                
                if(!olisOnFeature.contains(feat.Opportunity_Line_Item__c)){
                    parentsToInsert.add(feat);
                }
                
            }
            
            if(parentsToInsert.size()>  0)
                upsert parentsToInsert;
        }
        Map<String,OLI__c> existingPackageItem = new Map<String,OLI__c>();
        for (OLI__c ol :existingPackageContentOLIs) {
            existingPackageItem.put(ol.DQ__c, ol);
        }
        
        
        
        Map<String,Map<String,CN_Feature__c> >cnToCnFeatureMap = new Map<String,Map<String,CN_Feature__c> >();
        for (CN__C cn :[Select Name, (Select id,Name,Opportunity_Line_Item__c,Opportunity_Line_Item__r.dq__c From CN_Features__r) From CN__c Where ID IN:allcnid]) {
            Map<String,CN_Feature__c> temp = new Map<String,CN_Feature__c>();
            for (CN_Feature__c cnf :cn.CN_Features__r) {
                temp.put(cnf.Opportunity_Line_Item__r.dq__c, cnf);
            }
            cnToCnFeatureMap.put(cn.id, temp);
        }
        
        //Find the item which have been unselected and delete c
        for (wrapNumber tel :TelephoneNumbers) {
            for (wrapFeature feat :tel.features) {
                
                if (feat != NULL) {
                    if (feat.isPartOfPackage) {
                        if (tel.cn != NULL && feat.oli == null) {
                            System.debug('tel.cn: ' + tel.cn);
                            System.debug('feat: ' + feat);
                            System.debug('feat.name: ' + feat.name);
                            Map<String,CN_Feature__c> cnfeatureNameToCNFeature = cnToCnFeatureMap.get(tel.cn.id);
                            System.debug('cnfeatureNameToCNFeature: ' + cnfeatureNameToCNFeature);
                            if (feat.selected == false&&feat.additionalInformation == '') {
                                if(cnfeatureNameToCNFeature.get(feat.name) != null){
                                    deleteFeatures.add(cnfeatureNameToCNFeature.get(feat.name));
                                    oliToUpdateId.add(cnfeatureNameToCNFeature.get(feat.name).Opportunity_Line_Item__c);	
                                }
                                
                            }
                        }
                    }
                }
            }
        }
        if (!deletefeatures.isEmpty())delete deleteFeatures;
        List<CN_Feature__c> CNFeatures = new List<CN_Feature__c>();
        for (OLI__c ol :[Select id,DQ__C,QTY__c,SPC_Sales_Product_Component_Id__c, SPC_Component_Id__c,(Select id,name,Opportunity_Line_Item__c,CN__c from CN_Features__r) from OLI__c where OpportunityLocationConfiguration__c=:validations.OL.Id
                         AND PP_Package_Feature__c=true]) {
                             if (ol.CN_Features__r.size()== 0)deleteOLIs.add(ol);
                             else {
                                 ol.QTY__c = ol.CN_Features__r.size();
                                 updateOLIs.add(ol);
                                 CNFeatures.addAll(ol.CN_Features__r);
                             }
                         }
        if (!updateOLIs.isEmpty())update updateOLIs;
        if (!deleteOLIs.isEmpty())delete deleteOLIs;
        if (!updateNumbers.isEmpty())update updateNumbers;
        //New code added to handle non packag
        if (!insertNonPackage.isEmpty())CNFeatures.addall(insertNonPackage);
        boolean validate = validations.validateFeatureQty(CNFeatures);
        if (!validate) {
            for (String s :validations.errors) {
                messageDisplay(s);
            }
            if (deleteoli.isempty()) {
                Integer counter = 0;
                for (OLI__c exop :existingPackageContentOLIs) {
                    for (OLI__c newop :deleteoli) {
                        if (exop.DQ__c == exop.DQ__C) {
                            existingPackageContentOLIs.remove(counter);
                        }
                    }
                    counter ++;
                }
                delete deleteoli;
            }
            if (insertFeatures.isempty())delete insertFeatures;
            TelephoneNumbers.add(totalsLine);
            for (OLI__c ol :[Select id,DQ__C,QTY__c,SPC_Sales_Product_Component_Id__c, SPC_Component_Id__c,(Select id,name,Opportunity_Line_Item__c,CN__c from CN_Features__r) from OLI__c where OpportunityLocationConfiguration__c=:validations.OL.Id
                             AND PP_Package_Feature__c=true]) {
                                 if (ol.CN_Features__r.size()== 0)deleteOLIs.add(ol);
                                 else {
                                     ol.QTY__c = ol.CN_Features__r.size();
                                     updateOLIs.add(ol);
                                     CNFeatures.addAll(ol.CN_Features__r);
                                 }
                             }
            return null;
        }
        if (!insertNonPackage.isempty()){
            System.debug('KIT - NonPackage inserted: ' + insertNonPackage);
            //insert insertNonPackage;
        }
        return returnTechInfoNoRedirect();
    }
    public PageReference saveFeatures() {
        saveonly();
        return returnmanagelocationconfiguration();
    }
    public PageReference returnTechInfo() {
        PageReference p = new PageReference('/apex/managelocationconfigurations?opportunityId='+ this.currentTI.Opportunity_Site__r.Order__r.Opportunity__c);
        p.SetRedirect(true);
        return p;
    }
    public PageReference returnTechInfoNoRedirect() {
        messageDisplay('CurrentTI: '+ this.currentTI.Id);
        PageReference p = new PageReference('/apex/managefeaturesschedule?id='+ this.currentTI.Id);
        p.SetRedirect(true);
        return p;
    }
    public PageReference returnmanagelocationconfiguration() {
        PageReference p = new PageReference('/apex/managelocationconfigurations?opportunityId='+ validations.OL.Opportunity_Location__r.Opportunity__C);
        p.SetRedirect(true);
        return p;
    }
    public PageReference deleteLine() {
        Integer i = 0;
        for (wrapNumber tel :TelephoneNumbers) {
            if (!tel.isTotalLine) {
                if (tel.cn.Id == cnRemoveId) {
                    //Get rid of all the articifial OLIs that might exist (NOW, not later)
                    List<OLI__c> oliToDelete = new List<OLI__c>();
                    for (wrapFeature feat :tel.features) {
                        if (feat.isPartOfPackage) {
                            OLI__c oli = feat.OLI;
                            if (oli != null) {
                                if (oli.id != null) {
                                    //If it's already inserted
                                    oliToDelete.add(oli);
                                }
                                //Remove from all lists
                                removeOLIfromList(oli, insertedPackageContentOLIs);
                                removeOLIfromList(oli, existingPackageContentOLIs);
                                removeOLIfromList(oli, features);
                            }
                        }
                    }
                    if (oliToDelete.size()>0) {
                        delete oliToDelete;
                    }
                    //get rid of the features that I have adreed to delete (they will be auto-deleted in the next step)
                    //The for loop below is blowing up the app and not sure what it serves if features are auto deleted in the next step
                    //for (Integer x = deleteFeatures.size(); x> =-1; x-- ) {
                    //CN_Feature__c delFeat = deleteFeatures[x];
                    //if(delFeat.CN__r.Id == tel.cn.Id) {
                    //deleteFeatures.remove(x); 
                    //}
                    // }
                    //Get rid of the CN (CNFeatures will go automatically, as they are detail-records on a MD)
                    CN__c CN = tel.cn;
                    try {
                        delete CN;
                    }
                    catch (Exception e) {
                    }
                    //remove from lists
                    TelephoneNumbers.remove(i);
                    //Finally, if the numbers are still "iffy", then re-send the message
                    if (validations.totalLines <TelephoneNumbers.size()- 1) {
                        Decimal tLines = validations.totalLines;
                        messageDisplay('The number of lines in the current active solution is less than the amount in the Database. Please delete the excess lines before saving.');
                    }
                    return null;
                }
                i +=1;
            }
        }
        return null;
    }
    private void zeroOutPackageContentOLI() {
        //I zero them out
        for (OLI__c oli :existingPackageContentOLIs) {
            oli.Qty__c = 0;
        }
    }
    private OLI__c findPackageContentOLI(String productPricingId) {
        //if the feature I am evaluating has the same productPricingId than an OLI
        //currently in the DB then they are for the same feature
        for (OLI__c oli :existingPackageContentOLIs) {
            if (oli.DQ__c == productPricingId) {
                return oli;
            }
        }
        return null;
    }
    Map<String,List<CN_Feature__c> >packageItemToCncFeatureToInsert {get;set;}
    private void savePackageContentOLI(wrapFeature feat) {
        OLI__c oli;
        CN__c cn;
        //First look for this OLI somewhere in the collection already
        oli = findPackageContentOLI(feat.name);
        if (oli == null) {
            //If I don't find it, create it
            oli = new OLI__c();
            oli.Approved__c = true;
            oli.Approval_Status__c = 'Approved';
            oli.MRC_Discount__c = 0;
            oli.DQ__c = feat.name;
            oli.PP_Product_Pricing_Name__c = feat.name;
            oli.PP_Sales_Rate_Plan_Description__c = feat.name;
            oli.MRC__c = 0;
            oli.NRC__c = 0;
            oli.NRC_Discount__c = 0;
            oli.OpportunityLocationConfiguration__c = feat.parentOLI.OpportunityLocationConfiguration__c;
            oli.ParentName__c = feat.parentOLI.DQ__c;
            oli.Parent_Opportunity_Line_Item__c = feat.parentOLI.Id;
            oli.Qty__c = 1;
            oli.PP_Package_Feature__c = true;
            oli.PP_Sales_Product__c = feat.parentOLI.PP_sales_product__C;
            oli.Product_Family_Id__c = feat.parentOLI.Product_Family_Id__c;
            oli.PP_Product_Family__c = feat.parentOLI.PP_Product_Family__c;
            oli.Product_Family_Product__c = feat.parentOLI.Product_Family_Product__c;
            oli.PP_Voice_Line_Option__c = feat.parentOLI.PP_Voice_Line_Option__c;
            if (validations.packageItemToPriceId.containskey(feat.name))oli.Price_Id__c = validations.packageItemToPriceId.get(feat.name);
            oli.Tag__c = '';
            for (List<FeaturesScheduleValidations.wrapFeatureContent> pfeature :validations.packageFeatures.values()) {
                for (FeaturesScheduleValidations.wrapFeatureContent pfeat :pfeature) {
                    if (pfeat.Title == oli.DQ__c) {
                        oli.SPC_Sales_Product_Component_Id__c = decimal.valueof(pfeat.spcSalesProductComponentId);
                        oli.SPC_Component_Id__c = decimal.valueof(pfeat.spcComponentId);
                    }
                }
            }
            //Insert 1 by 1 because I need the ID
            //insert oli;
            oli = setupField(oli);
            insertedPackageContentOLIs.add(oli);
            features.add(oli);
            CN_Feature__c cncfeature = new CN_Feature__c();
            if (nameToCn.containskey(feat.name)) {
                cncfeature.CN__c = nameToCn.get(feat.name).id;
                cncfeature.name = nameToCn.get(feat.name).name + '-'+ oli.DQ__c;
                cncfeature.Opportunity_Line_Item__c = oli.id;
                if (feat.additionalInformation != '')cncfeature.Additional_Info__c = feat.additionalInformation;
            }
            if (!packageItemToCncFeatureToInsert.containskey(oli.DQ__c))packageItemToCncFeatureToInsert.put(feat.name, new List<CN_Feature__c> {
                cncfeature }
                                                                                                           );
            else packageItemToCncFeatureToInsert.get(feat.name).add(cncfeature);
            existingPackageContentOLIs.add(oli);
        }
        else {
            oli.ParentName__c = feat.parentOLI.DQ__c;
            oli.Parent_Opportunity_Line_Item__c = feat.parentOLI.Id;
            oli.PP_Package_Feature__c = true;
            oli.Product_Family_Id__c = feat.parentOLI.Product_Family_Id__c;
            oli.PP_Product_Family__c = feat.parentOLI.PP_Product_Family__c;
            oli.Product_Family_Product__c = feat.parentOLI.Product_Family_Product__c;
            oli.PP_Voice_Line_Option__c = feat.parentOLI.PP_Voice_Line_Option__c;
            CN_Feature__c cncfeature = new CN_Feature__c();
            if (nameToCn.containskey(feat.name)) {
                cncfeature.CN__c = nameToCn.get(feat.name).id;
                cncfeature.name = nameToCn.get(feat.name).name + '-'+ oli.DQ__c;
                cncfeature.Opportunity_Line_Item__c = oli.id;
                if (feat.additionalInformation != '')cncfeature.Additional_Info__c = feat.additionalInformation;
            }
            for (List<FeaturesScheduleValidations.wrapFeatureContent> pfeature :validations.packageFeatures.values()) {
                for (FeaturesScheduleValidations.wrapFeatureContent pfeat :pfeature) {
                    if (pfeat.Title == oli.DQ__c) {
                        oli.SPC_Sales_Product_Component_Id__c = decimal.valueof(pfeat.spcSalesProductComponentId);
                        oli.SPC_Component_Id__c = decimal.valueof(pfeat.spcComponentId);
                    }
                }
            }
            List<CN_Feature__c> cnfeaturelst = oppnameToCnFeaturelst.get(feat.name);
            CN_Feature__c updatecnfeature = new CN_Feature__c();
            boolean existed = false;
            boolean updatefeature = false;
            if (cnfeaturelst != NULL &&!cnfeaturelst.isEmpty()) {
                for (CN_Feature__c ol :cnfeaturelst) {
                    if (ol.name == cncfeature.name) {
                        existed = true;
                        if (ol.Additional_Info__c != feat.additionalInformation) {
                            updatefeature = true;
                            updatecnfeature = ol;
                            updatecnfeature.Additional_Info__c = feat.additionalInformation;
                        }
                        break ;
                    }
                }
            }
            if (!existed) {
                oliToupdateId.add(oli.id);
                existingPackageContentOLIs.add(oli);
                insertedPackageContentOLIs.add(oli);
                if (!packageItemToCncFeatureToInsert.containskey(oli.DQ__c))packageItemToCncFeatureToInsert.put(feat.name, new List<CN_Feature__c> {
                    cncfeature }
                                                                                                               );
                else packageItemToCncFeatureToInsert.get(feat.name).add(cncfeature);
            }
            if (updatefeature) {
                insertedPackageContentOLIs.add(oli);
                if (!packageItemToCncFeatureToInsert.containskey(oli.DQ__c))packageItemToCncFeatureToInsert.put(feat.name, new List<CN_Feature__c> {
                    updatecnfeature }
                                                                                                               );
                else packageItemToCncFeatureToInsert.get(feat.name).add(updatecnfeature);
            }
        }
    }
    public OLI__c setupField(OLI__c lineItem) {
        if (validations.newView != NULL ) {
            System.debug('MNK ManageFeaturesScheduleController setupField');
            for (CatalogUtils.SPCPricingView pricingView :validations.newview) {
                if (pricingView.children != NULL ) {
                    for (CatalogUtils.SPCPricingView childView :pricingView.Children) {
                        if (childView.pricing.Component_name__c == lineItem.DQ__c &&childView.pricing.Component_Group__c == 'Included') {
                            lineItem.PP_Feature_Group__c = childview.pricing.Component_Group__c;
                            lineItem.PP_Product_Family__C = childview.pricing.Sales_Product_Group__c;
                            lineItem.PP_Sales_Product__c = childview.pricing.Sales_product_name__c;
                            if (childView.pricing.Feature_Schedule_Prompt__c != NULL)lineItem.PP_AdditionalInformationPrompt__c = childView.pricing.Feature_Schedule_Prompt__c;
                            break ;
                        }
                    }
                }
            }
            
        }
        return lineitem;
    }
    private Id updatePackageContentOLI(wrapFeature feat) {
        System.debug('MNK ManageFeatureScheduleController updatePackageContentOLI');
        Id oliID = null;
        OLI__c oli;
        //First look for this OLI somewhere in the collection already
        oli = findPackageContentOLI(feat.productPricingId);
        if (oli != null) {
            //If I find it, add 1 to the Qty
            oli.Qty__c +=1;
        }
        if (oli != NULL &&oli.id != NULL) {
            oliID = oli.Id;
            return oliID;
        }
        return null;
    }
    private void removeOLIfromList(OLI__c oliToDelete, List<OLI__c> theList) {
        for (Integer i = 0;
             i <theList.size();
             i ++) {
                 OLI__c existingOLI = theList [i ];
                 if (existingOLI.id == oliToDelete.Id) {
                     theList.remove(i);
                     return ;
                 }
             }
    }
    private void addToTitles(OLI__c oli) {
        System.debug('MNK ManageFeatureScheduleController addToTitles');
        wrapFeatureTitle tit = new wrapFeatureTitle();
        tit.displayTitle = oli.PP_Sales_Rate_Plan_Description__c;
        if (!oli.PP_Per_Account__c ||!oli.PP_Package__c) {
            tit.displaySubTitle = '(Max: '+ oli.Qty__c + ')';
        }
        tit.additionalInformationPrompt = (oli.PP_AdditionalInformationPrompt__c == null)?'':oli.PP_AdditionalInformationPrompt__c;
        tit.isFeaturePackage = false;
        displayFeatures.add(tit);
        //Now do the display part
        if (packageFeatures.containsKey(oli.Id)) {
            List<FeaturesScheduleValidations.wrapFeatureContent> myFeatures = packageFeatures.get(oli.Id);
            for (FeaturesScheduleValidations.wrapFeatureContent feat :myFeatures) {
                wrapFeatureTitle featTit = new wrapFeatureTitle();
                featTit.displayTitle = feat.title;
                if (!oli.PP_Per_Account__c ||!oli.PP_Package__c) {
                    featTit.displaySubTitle = '(Max: '+ oli.Qty__c + ')';
                }
                featTit.additionalInformationPrompt = (feat.additionalInformationPrompt == null)?'':feat.additionalInformationPrompt;
                featTit.isFeaturePackage = true;
                tit.childrenNumber +=1;
                if (featTit.additionalInformationPrompt != '') {
                    //add another child b/c of the textbox that we add
                    tit.childrenNumber +=1;
                }
                displayFeatures.add(featTit);
            }
        }
    }
    private void addToColumnFeatures(wrapNumber tel, OLI__c oli) {
        System.debug('MNK ManageFeatureScheduleController addToColumnFeatures');
        wrapFeature feat = new wrapFeature();
        feat.OLI = oli;
        feat.name = oli.PP_Sales_Rate_Plan_Description__c;
        feat.additionalInformationPrompt = (oli.PP_AdditionalInformationPrompt__c == null)?'':oli.PP_AdditionalInformationPrompt__c;
        feat.maxQty = oli.Qty__c;
        feat.isPartOfPackage = false;
        feat.parentFeature = null;
        feat.parentOLI = null;
        if (!oli.PP_Per_Account__c) {
            feat.salesProduct = oli.PP_Sales_Product__c;
        }
        else {
            feat.salesProduct = '_ALL_';
        }
        feat.salesProductRatePlanExternalId = oli.PP_SalesProductRatePlanExternalID__c;
        //feat.productPricingId = oli.Product_Pricing__c;
        feat.selected = false;
        feat.additionalInformation = '';
        feat.childrenNumber = 0;
        feat.spcSalesProductComponentId = string.valueof(oli.SPC_Sales_Product_Component_Id__c);
        feat.spcComponentId = string.valueof(oli.SPC_Component_Id__c);
        tel.features.add(feat);
        //Now see if I have to enter features from within a package.
        if (packageFeatures.containsKey(oli.Id)) {
            List<FeaturesScheduleValidations.wrapFeatureContent> myFeatures = packageFeatures.get(oli.Id);
            for (FeaturesScheduleValidations.wrapFeatureContent packageFeat :myFeatures) {
                wrapFeature featcontent = new wrapFeature();
                featcontent.OLI = null;
                featcontent.name = packageFeat.title;
                featcontent.additionalInformationPrompt = (packageFeat.additionalInformationPrompt == null)?'':packageFeat.additionalInformationPrompt;
                featcontent.maxQty = oli.Qty__c;
                featcontent.isPartOfPackage = true;
                featcontent.parentFeature = feat;
                featcontent.parentOLI = oli;
                featcontent.spcSalesProductComponentId = string.valueof(oli.SPC_Sales_Product_Component_Id__c);
                featcontent.spcComponentId = string.valueof(oli.SPC_Component_Id__c);
                if (!oli.PP_Per_Account__c) {
                    featcontent.salesProduct = oli.PP_Sales_Product__c;
                }
                else {
                    featcontent.salesProduct = '_ALL_';
                }
                featcontent.salesProductRatePlanExternalId = packageFeat.salesProductRatePlanExternalId;
                featcontent.productPricingId = packageFeat.productPricingId;
                featcontent.selected = false;
                featcontent.additionalInformation = '';
                feat.childrenNumber +=1;
                if (featcontent.additionalInformationPrompt != '') {
                    //add another child b/c of the textbox that we add
                    feat.childrenNumber +=1;
                }
                tel.features.add(featcontent);
            }
        }
    }
    private Boolean validateRecords() {
        //First Create two Lists to send to the validation Engine
        //Because I have to "remove the wrappers"
        //Since this is only called on "save" after I remove the "Totals" line, I don't have to evaluate here
        List<CN__c> CNs = new List<CN__c>();
        List<CN_Feature__c> CNFeatures = new List<CN_Feature__c>();
        for (wrapNumber tel :TelephoneNumbers) {
            CNs.add(tel.cn);
            for (wrapFeature feat :tel.features) {
                if (feat.feature != null) {
                    CNFeatures.add(feat.feature);
                }
            }
        }
        Boolean success = validations.validate(CNs, CNFeatures);
        if (!success) {
            for (String str :validations.errors) {
                messageDisplay(str);
            }
        }
        return success;
    }
    private String findSalesProduct(Id oliID) {
        for (OLI__c prod :products) {
            if (prod.Id == oliID) {
                return prod.PP_Sales_Product__c;
            }
        }
        return '';
    }
    private wrapFeature findFeature(CN_Feature__c cnfeat, List<wrapFeature> features) {
        System.debug('MNK ManageFeatureScheduleController findFeature');
        String sprtId = cnfeat.Opportunity_Line_Item__r.PP_SalesProductRatePlanExternalID__c;
        for (wrapFeature feat :features) {
            if (feat.OLI != null &&feat.OLI.Id == cnfeat.Opportunity_Line_Item__c) {
                return feat;
            }
            else if (feat.OLI == null &&feat.isPartOfPackage == true&&feat.salesProductRatePlanExternalId == sprtId) {
                //if this is a feature that is part of a package, then the OpptyLineItem was defaulted to null above
                //therefore, we have to compare differently
                return feat;
            }
        }
        return null;
    }
    private void decreaseMap(Id oliID) {
        if (oliCount.containsKey(oliID)) {
            Decimal newQty = oliCount.get(oliID);
            newQty -=1;
            olicount.put(oliID, newQty);
        }
    }
    private Id findNextOpenOLI() {
        for (Id oliID :oliCount.keySet()) {
            Decimal qty = oliCount.get(oliID);
            if (qty> 0) {
                return oliId;
            }
        }
        return null;
    }
    private void preselectCheckboxes() {
        //Iterate through all the features
        //If the qty of the feature = qty of the line they belong to
        //then preselect
        for (wrapNumber tel :TelephoneNumbers) {
            if (!tel.isTotalLine) {
                if (tel.cn.Opportunity_Line_Item__c != null) {
                    //Always find the proper SP based on the selection just made (the retrieved one could be old)
                    String salesProduct = findSalesProduct(tel.cn.Opportunity_Line_Item__c);
                    //If the line has been assigned, check all its features for the possibility  
                    for (wrapFeature feat :tel.features) {
                        if ((feat.salesProduct == salesProduct)||(feat.salesProduct == '_ALL_')) {
                            if (oliQty.containsKey(tel.cn.Opportunity_Line_Item__c)&&!feat.isPartOfPackage) {
                                Decimal qty = oliQty.get(tel.cn.Opportunity_Line_Item__c);
                                if (feat.maxQty == qty) {
                                    feat.selected = true;
                                }
                            }
                        }
                        if (cncToCnCFeatures.containskey(tel.cn.Name)) {
                            if (cncToCnCFeatures.get(tel.cn.Name).containskey(tel.cn.Name + ' - '+ feat.name)&&(feat.additionalInformationPrompt == NULL ||feat.additionalInformationPrompt.trim().isWhitespace()))feat.selected = true;
                            else if (cncToCnCFeatures.get(tel.cn.Name).containskey(tel.cn.Name + ' - '+ feat.name))feat.additionalInformation = cncToCnCFeatures.get(tel.cn.Name).get(tel.cn.Name + ' - '+ feat.name).Additional_Info__c;
                        }
                    }
                }
            }
        }
    }
    private void preselectPackages(wrapNumber tel) {
        //Empty all the packages
        for (wrapFeature feat :tel.features) {
            if (feat.childrenNumber != 0) {
                feat.selected = false;
            }
        }
        //Select those with a parent
        for (wrapFeature feat :tel.features) {
            if (feat.selected &&feat.isPartOfPackage) {
                feat.parentFeature.selected = true;
            }
        }
    }
    //Classes to iterate through the columns
    public class wrapFeatureTitle {
        @AuraEnabled public String displayTitle {get;set;}
        @AuraEnabled public String displaySubtitle {get;set;}
        @AuraEnabled public string additionalInformationPrompt {get;set;}
        @AuraEnabled public Boolean isFeaturePackage {get;set;}
        @AuraEnabled public Integer childrenNumber {get;set;}
        public wrapFeatureTitle() {
            this.displayTitle = '';
            this.displaySubtitle = '';
            this.additionalInformationPrompt = '';
            this.isFeaturePackage = false;
            this.childrenNumber = 0;
        }
    }
    public class wrapNumber {
        @AuraEnabled public CN__c cn {get;set;}
        @AuraEnabled public List<wrapFeature> features {get;set;}
        @AuraEnabled public Boolean deletable {get;set;}
        @AuraEnabled public Boolean changeable {get;set;}
        @AuraEnabled public Boolean isTotalLine {get;set;}
        public wrapNumber(CN__c pCN) {
            this.cn = pCN;
            this.deletable = false;
            this.changeable = false;
            this.isTotalLine = false;
            this.features = new List<wrapFeature>();
        }
        public wrapNumber() {
            this.cn = null;
            this.deletable = false;
            this.changeable = false;
            this.isTotalLine = true;
            this.features = new List<wrapFeature>();
        }
    }

    public class wrapFeature {
        //Feature Specific
        @AuraEnabled public CN_Feature__c feature {get;set;}
        @AuraEnabled public Boolean selected {get;set;}
        @AuraEnabled public String additionalInformation{get;set;}
        @AuraEnabled public Boolean disabled {get;set;}
        //Line Item / Pricing specific
        @AuraEnabled public OLI__c OLI {get;set;}
        @AuraEnabled public OLI__c parentOLI {get;set;}
        @AuraEnabled public string additionalInformationPrompt {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public Decimal maxQty {get;set;}
        @AuraEnabled public string salesProduct {get;set;}
        @AuraEnabled public string salesProductRatePlanExternalId {get;set;}
        @AuraEnabled public Id productPricingId {get;set;}
        @AuraEnabled public wrapFeature parentFeature {get;set;}
        @AuraEnabled public Boolean isPartOfPackage {get;set;}
        @AuraEnabled public Integer childrenNumber {get;set;}
        @AuraEnabled public string spcSalesProductComponentId {get;set;}
        @AuraEnabled public string spcComponentId {get;set;}
        public wrapFeature() {
            this.OLI = null;
            this.parentOLI = null;
            this.name = '';
            this.additionalInformationPrompt = '';
            this.maxQty = 0;
            this.salesProduct = '';
            this.salesProductRatePlanExternalId = null;
            this.productPricingId = null;
            this.isPartOfPackage = false;
            this.parentFeature = null;
            this.childrenNumber = 0;
            this.spcSalesProductComponentId = '';
            this.spcComponentId = '';
            this.feature = null;
            this.selected = false;
            this.additionalInformation = '';
            this.disabled = false;
        }
    }
    /* TestUtils.ITestableClass methods */
    
    public TestUtils.TestClass getTestClass() {
        return new Test_ManageFeaturesSchedule();
    }
    
    public class wrapFieldSet {
        @AuraEnabled public Boolean dbRequired {get;set;}
        @AuraEnabled public String fieldPath {get;set;}
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public Boolean required {get;set;}
        public wrapFieldSet(){}
        public wrapFieldSet(Schema.FieldSetMember fsm) {
            this.dbRequired = fsm.dbRequired;
            this.fieldPath = String.valueOf(fsm.fieldPath);
            this.label = String.valueOf(fsm.label);
            this.required = fsm.required;
        }
    }
    
}