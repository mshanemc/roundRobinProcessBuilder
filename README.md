# Round robin assignments of any object via Process Builder and Public Groups

Assuming you have
* a group (`Users > Public Groups`, **not Chatter Groups**) with at least 1 user in it
* some object that has an ownerId field OR a user lookup (that is, not child of a master detail relationship!)

Assign the object to members of the group, sequentially ("round-robin") the object via Process Builder

## Setup

1. Create a Process on the object you want, and specify your criteria
2. Apex Action, call it whatever you like
3. Select `Assign Objects` from the apex classes
4. Specify the group name (label, not API name) and the recordId (both are required)
5. Optionally, put in the API name of a field you'd like to use **instead of** ornwerId (the default).




## Behind the scenes

It's automatically creating a custom setting for each comination of object/field/group and tracking which group member received the last assignment.

There should be no reason to touch this setting unless you feel like deleting something no longer in use.


## no code install

It's a developer controlled package.  Use the `SubscriberPackageVersionId` from latestVersion.

put that in your url like `/packagingSetupUI/ipLanding.app?apvId=04t6A000002HkBGQA0` where 04t6A000002HkBGQA0 is that `SubscriberPackageVersionId`

## sfdx install

`sfdx force:package:install -r -p 20 -w 20 -i [latestVersion.SubscriberPackageVersionId] -u [orgAlias/username]`

## Support

There is none.


