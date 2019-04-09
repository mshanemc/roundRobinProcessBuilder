sfdx force:source:convert --outputdir packageSrc --rootdir force-app --packagename RoundRobinAssigner
sfdx force:mdapi:deploy --deploydir packageSrc -u ltngSharingPkg -w 20
sfdx force:package1:version:create --packageid 03346000000E0RY --name Latest -u ltngSharingPkg -m -w 20 -r https://github.com/mshanemc/roundRobinProcessBuilder -p https://github.com/mshanemc/roundRobinProcessBuilder

# sfdx force:package2:version:create -d force-app/ -w 20 --json | jq '.result' > latestVersion
# sfdx force:package2:version:update -s -p -i $(cat latestVersion | jq '.Package2VersionId' | tr -d '"')
# echo sfdx force:package:install -r -p 20 -w 20 -i $(cat latestVersion | jq '.SubscriberPackageVersionId' | tr -d '"')