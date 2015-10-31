#
# Parameter.psm1
#

$Global:Environment="test1"
$Global:SubscriptionId=""

$Global:Location = "West Europe"
$Global:DBResourceGroupName = "titotestrg$Environment"
$Global:SqlServerName = "titotestsqlserver$Environment"
$Global:DynamicParameterHash = New-Object -TypeName Hashtable
$Global:TargetSqlServerUpgradeVersion = "12.0"
$Global:DeploymentConfig = "Dev" # Allowed values [Dev,Prod]