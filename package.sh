sfdx force:package2:version:create -d force-app/ -w 20 --json | jq '.result' > latestVersion
sfdx force:package2:version:update -s -p -i $(cat latestVersion | jq '.Package2VersionId' | tr -d '"')
echo sfdx force:package:install -r -p 20 -w 20 -i $(cat latestVersion | jq '.SubscriberPackageVersionId' | tr -d '"')