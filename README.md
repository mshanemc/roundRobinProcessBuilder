# Round robin assignments of any object via Process Builder and Public Groups

[Latest Manage Package Install Link](https://login.salesforce.com/packagingSetupUI/ipLanding.app?apvId=04t46000001hhYrAAI)

## What is it

Assuming you have

* a group (`Users > Public Groups`, **not Chatter Groups**, **Not any of the generic groups like "All Internal Users**) with at least 1 user in it
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

I used the dreaded `without sharing` keyword because I ran into a scenario where process builder was triggered by an action in a customer community (whose users don't have groupMember object access) and so an error was being thrown

## Quirks

Because of how I'm creating a unique tracker for each setting (using object/field/group) if you have some really long descriptive names it's possible to overflow the allowed length for a custom setting name (40), so that's capped at 40 char.  This may result in truncation in the custom settings name.

That doesn't impact the functionality but might make it harder for an admin to look through the custom settings and know which one is which

## no code install

It's a developer controlled package.  Use the `04t...` from the latest version in sfdx-project.json.

put that in your url like `/packagingSetupUI/ipLanding.app?apvId=04t6A000002HkBGQA0` where 04t6A000002HkBGQA0 is that `04t`

## sfdx install

core sfdx

`sfdx force:package:install -r -p 20 -w 20 -i [get the versionId from the sfdx-project.json file] -u [orgAlias/username]`

alternatively, if you're using [my sfdx plugin](https://github.com/mshanemc/shane-sfdx-plugins) it's just

`sfdx shane:github:package:install -g mshanemc -r roundRobinAssigner -u [orgAlias/username]`

## Support

Log an issue here in github.  Not an officially supported Salesforce product, just sharing to be a nice person.