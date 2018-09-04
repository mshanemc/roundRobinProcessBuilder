sfdx force:org:create -s -f config/project-scratch-def.json -d 1
sfdx force:source:push

sfdx force:org:open -p /lightning/setup/ProcessAutomation/home