public without sharing class JunctionUtils{

	public class Junction{
		public sObject Source { get; private set; }
		public sObject Target { get; private set; }
		public Id JunctionID { get; set; }
		
		public Junction(){ }
		
		public Junction(sObject source, sObject target, Id id){
			this.Source = source;
			this.Target = target;
			JunctionID = id;
		}
		
		public void SetSource(SObject source){
			this.Source = source;
		}
		
		public void SetSource(Id id){
			SetSource(SchemaUtils.GetSObjectTypeByID(id).newSObject(id));
		}
		
		public void SetTarget(SObject target){
			this.Target = target;
		}
		
		public void SetTarget(Id id){
			SetTarget(SchemaUtils.GetSObjectTypeByID(id).newSObject(id));
		}
	}
	
	public static List<Junction> GetJunctions(Set<Id> validSourceIDs, Set<Id> validTargetIDs){
		List<Junction> l = new List<Junction>();
		for(Junction__c j : [select Id, Source_ID__c, Target_ID__c from Junction__c where Source_ID__c in: validSourceIDs and Target_ID__c in: validTargetIDs]){
			Schema.SObjectType sOt = SchemaUtils.GetSObjectTypeByID(j.Source_ID__c);
			Schema.SObjectType tOt = SchemaUtils.GetSObjectTypeByID(j.Target_ID__c);
			if(sOt != null && tOt != null){
				l.add(new Junction(sOt.newSObject(j.Source_ID__c), tOt.newSObject(j.Target_ID__c), j.Id));
			}
		}
		return l;
	}
	
	public static List<Junction> GetSOrTBasedJunctions(Set<Id> validSourceIDs, Set<Id> validTargetIDs){
		List<Junction> l = new List<Junction>();
		List<String> types = new List<String>();
		types.add('Sub_Order__c');
		types.add('Order__c');
		for(Junction__c j : [select Id, Source_ID__c, Target_ID__c from Junction__c where (Source_ID__c in: validSourceIDs and Target_ID__c in: validTargetIDs) or (Source_ID__c in: validSourceIDs and Target_Type__c in: types)]){
			Schema.SObjectType sOt = SchemaUtils.GetSObjectTypeByID(j.Source_ID__c);
			Schema.SObjectType tOt = SchemaUtils.GetSObjectTypeByID(j.Target_ID__c);
			if(sOt != null && tOt != null){
				l.add(new Junction(sOt.newSObject(j.Source_ID__c), tOt.newSObject(j.Target_ID__c), j.Id));
			}
		}
		return l;
	}
	
	public static List<Database.UpsertResult> SaveJunctions(List<Junction> jList){
		List<Junction__c> l = convert(jList);
		
		List<Database.UpsertResult> rList = Database.Upsert(l, true);
		for(Integer i=0; i<rList.size(); i++)
			jList[i].JunctionID = rList[i].Id;
		return rList;
	}
	
	public static List<Database.DeleteResult> DeleteJunctions(List<Junction> jList){
		List<Junction__c> l = convert(jList);
		return Database.Delete(l, true);
	}
	
	private static List<Junction__c> convert(List<Junction> jList){
		List<Junction__c> l = new List<Junction__c>();
		for(Junction j : jList){
			Junction__c oj = new Junction__c(Source_ID__c = j.Source.Id, Target_ID__c = j.Target.Id, Source_Type__c = SchemaUtils.GetSObjectNameByID(j.Source.Id), Target_Type__c = SchemaUtils.GetSObjectNameByID(j.Target.Id));
			if(j.JunctionID != null) oj.Id = j.JunctionID;
			l.add(oj);
		}
		return l;
	}
}