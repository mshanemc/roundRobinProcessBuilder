public without sharing class roundRobinAssigner {

    @InvocableMethod(label='Assign objects')
	public static void assign(list<RoundRobinAssignment> rras) {

        // what was the last user index?
        list<RoundRobin__c> RRSettings = [select id, GroupName__c, FieldName__c, Object__c, IndexOfLastUsed__c from RoundRobin__c];

        set<Id> recordIds = new set<Id>();

        map<string, list<GroupMember>> usersByGroup = new map<string, list<GroupMember>>();
        List<SObject> objectList = new List<SObject>();

        // get the records
        for (RoundRobinAssignment rra:rras){
            // default field
            if (rra.fieldName == null){
                rra.fieldName = 'OwnerId';
            }

            list<groupMember> groupUsers = new list<groupMember>();
            // see if we have it already in our map
            if (usersByGroup.get(rra.groupName) == null){
                groupUsers = [select Group.Name, GroupId, UserOrGroupId from GroupMember where Group.Name =: rra.groupName];
                //store in the map so we don't have to query about this group again
                usersByGroup.put(rra.groupName, groupUsers);
            } else {
                groupUsers = usersByGroup.get(rra.groupName);
            }
            // what kind of object is this, anyway?
            Id rId = id.valueOf(rra.recordId);
			string Obj = rid.getSObjectType().getDescribe().getName();

            RoundRobin__c matchingRR = recordMatcher(RRSettings, rra.fieldName, Obj, rra.groupName);


            sObject so = rid.getSObjectType().newSObject(rid);
            integer nextIndex = getNextIndex(matchingRR, groupUsers);
            so.put(rra.fieldName, groupUsers[nextIndex].UserOrGroupId);

            matchingRR.IndexOfLastUsed__c = nextIndex;

            // if the original list didn't contain the matching one, we need to add it here
            boolean isNew = true;
            for (RoundRobin__c rr: RRSettings){
                // we already had that on our list
                if (rr.Id == matchingRR.Id){
                    rr.IndexOfLastUsed__c = matchingRR.IndexOfLastUsed__c;
                    isNew = false;
                }
            }
            if (isNew){
                //we hadn't seen it before
                system.debug('inserting a RR custom setting');
                RRSettings.add(matchingRR);
            }

            objectList.add(so);
		}

        update objectList;

        // because we may have incremented them
        update RRSettings;

	}

    public static integer getNextIndex(RoundRobin__c match, list<GroupMember> groupUsers){
        if (match.IndexOfLastUsed__c == null){
            // it's null, so grab the first one!
            return 0;
        } else if (match.IndexOfLastUsed__c >= groupUsers.size()-1){
            // you've used them all
            system.debug(match.IndexOfLastUsed__c + ' is the last match, which is >= the group size of ' + groupUsers.size() + 'so we are going back to 0' );
            return 0;
        } else {
            // return the next one
            return integer.valueOf(match.IndexOfLastUsed__c + 1);
        }
    }

    public static RoundRobin__c recordMatcher(list<RoundRobin__c> records, string FieldName, string Obj, string GroupName){

        for (RoundRobin__c rr:records){
            if (rr.FieldName__c == FieldName && rr.Object__c == Obj && rr.GroupName__c == GroupName){
                return rr;
            }
        }

        // we never found it, so create one
        RoundRobin__c rrNew = new RoundRobin__c();
        rrNew.FieldName__c = FieldName;
        rrNew.Object__c = Obj;
        rrNew.GroupName__c = GroupName;
        // because name is required
        rrNew.Name = Obj + '-' + FieldName + '-' + GroupName;
        insert rrNew;
        return rrNew;
    }

    //what Process Builder/Flow Builder can reference for the input variables
	public class RoundRobinAssignment {
		@InvocableVariable(required=true label='group name')
		public string groupName;

        @InvocableVariable(required=true label='recordId')
		public string recordId;

		@InvocableVariable(required=false label='field name (default = ownerId)')
		public string fieldName;
	}


}
