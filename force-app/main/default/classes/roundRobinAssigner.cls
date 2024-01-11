public without sharing class roundRobinAssigner {
  public static final integer customSettingNameLimitLength = 38;

  // Invocable method to be called from Process Builder or Flow
  @InvocableMethod(label='Assign objects')
  public static void assign(List<RoundRobinAssignment> rras) {
    if(rras.isEmpty()) {
        return; // Exit if there are no assignments to process
    }

    // Retrieve existing RoundRobin settings
    List<RoundRobin__c> RRSettings = [
      SELECT Id, GroupName__c, FieldName__c, Object__c, IndexOfLastUsed__c
      FROM RoundRobin__c
    ];

    // Collect all unique group names from assignments
    Set<String> groupNames = new Set<String>();
    for (RoundRobinAssignment rra : rras) {
        groupNames.add(rra.groupName);
    }

    // Bulk fetch GroupMember records for each group
    Map<String, List<GroupMember>> usersByGroup = new Map<String, List<GroupMember>>();
    for (GroupMember gm : [SELECT Group.Name, GroupId, UserOrGroupId FROM GroupMember WHERE Group.Name IN :groupNames]) {
      if (!usersByGroup.containsKey(gm.Group.Name)) {
        usersByGroup.put(gm.Group.Name, new List<GroupMember>());
      }
      usersByGroup.get(gm.Group.Name).add(gm);
    }

    List<SObject> objectList = new List<SObject>();
    Map<String, RoundRobin__c> newRRSettingsMap = new Map<String, RoundRobin__c>();

    for (RoundRobinAssignment rra : rras) {
      // Default to 'OwnerId' if fieldName is not specified
      String fieldName = rra.fieldName != null ? rra.fieldName : 'OwnerId';
      Id rId = Id.valueOf(rra.recordId);
      String Obj = rId.getSObjectType().getDescribe().getName();

      // Generate unique name for new RoundRobin setting
      String uniqueName = nameShortener(Obj, fieldName, rra.groupName);
      RoundRobin__c matchingRR = newRRSettingsMap.get(uniqueName);

      // Find or create a new RoundRobin setting for the assignment
      if (matchingRR == null) {
        matchingRR = findMatchingRR(RRSettings, fieldName, Obj, rra.groupName);
        if (matchingRR == null) {
          matchingRR = new RoundRobin__c(
            FieldName__c = fieldName,
            Object__c = Obj,
            GroupName__c = rra.groupName,
            Name = uniqueName
          );
          newRRSettingsMap.put(uniqueName, matchingRR);
        }
      }

      // Create SObject record to update and add to objectList
      SObject recordToUpdate = rId.getSObjectType().newSObject(rId);
      List<GroupMember> groupUsers = usersByGroup.get(rra.groupName);
      Integer nextIndex = getNextIndex(matchingRR, groupUsers);
      recordToUpdate.put(fieldName, groupUsers[nextIndex].UserOrGroupId);
      matchingRR.IndexOfLastUsed__c = nextIndex;

      objectList.add(recordToUpdate);
    }

    // Perform bulk DML operations outside of the loop
    update objectList;
    insert newRRSettingsMap.values();
    update RRSettings;
  }

  // Helper method to find a matching RoundRobin setting
  private static RoundRobin__c findMatchingRR(List<RoundRobin__c> records, String fieldName, String objName, String groupName) {
      for (RoundRobin__c rr : records) {
          if (rr.FieldName__c == fieldName && rr.Object__c == objName && rr.GroupName__c == groupName) {
              return rr;
          }
      }
      return null;
  }
  
  // Determine the next index for Round Robin assignment
  public static integer getNextIndex( RoundRobin__c match, list<GroupMember> groupUsers) {
    if (groupUsers.size() == 0) throw new IllegalArgumentException(
                'Round Robin Assigner: No members of ' + match.GroupName__c + ' found');
    else if (match.IndexOfLastUsed__c == null) {
      // it's null, so grab the first one!
      return 0;
    } else if (match.IndexOfLastUsed__c >= groupUsers.size() - 1) {
      // you've used them all
      system.debug(
        match.IndexOfLastUsed__c +
        ' is the last match, which is >= the group size of ' +
        groupUsers.size() +
        'so we are going back to 0'
      );
      return 0;
    } else {
      // return the next one
      return integer.valueOf(match.IndexOfLastUsed__c + 1);
    }
  }
  
    
  // Shortens the composite name to fit within the character limit
  public static string nameShortener(
    string Obj,
    string FieldName,
    string GroupName
  ) {
    integer tooLongness =
      Obj.length() +
      FieldName.length() +
      GroupName.length() +
      2 -
      customSettingNameLimitLength; // for separators
    while (tooLongness > 0) {
      if (Obj.length() > 10) Obj = Obj.left(Obj.length() - 1);
      if (FieldName.length() > 10) FieldName = FieldName.left(FieldName.length() - 1);
      if (GroupName.length() > 10) GroupName = GroupName.left(GroupName.length() - 1);

      tooLongness =
        Obj.length() +
        FieldName.length() +
        GroupName.length() +
        2 -
        customSettingNameLimitLength;
    }

    return Obj + '-' + FieldName + '-' + GroupName;
  }
  
   // Inner class to represent each assignment operation
  public class RoundRobinAssignment {
    @InvocableVariable(required=true label='group name')
    public string groupName;

    @InvocableVariable(required=true label='recordId')
    public string recordId;

    @InvocableVariable(required=false label='field name (default = ownerId)')
    public string fieldName;
  }
}
  
