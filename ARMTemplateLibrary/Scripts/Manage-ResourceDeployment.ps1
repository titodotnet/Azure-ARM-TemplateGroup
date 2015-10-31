#
# Manage_ResourceDeployment.ps1
#

Import-Module (Join-Path $PSScriptRoot "Common\Parameter.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "Common\Utility.psm1") -DisableNameChecking

Import-Module (Join-Path $PSScriptRoot "Preparation\SQLServerPreparation.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "Preparation\SqlDBPreparation.psm1") -DisableNameChecking


$TemplateFile = '..\Templates\DeploymentTemplate.json'
$TemplateParametersFile = '..\Templates\DeploymentTemplate.param.dev.json'
$UpdatedTemplateParametersFile = '..\Templates\DeploymentTemplateUpdated.param.dev.json'

$TemplateFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateFile)
$TemplateParametersFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile)
$UpdatedTemplateParametersFile = [System.IO.Path]::Combine($PSScriptRoot, $UpdatedTemplateParametersFile)

$SqlDBDeploymentTemplatePath = "..\Templates\MainTemplate\SqlDB\SqlDBDeploymentTemplate.json"
$SqlDBDeploymentTemplatePath = [System.IO.Path]::Combine($PSScriptRoot, $SqlDBDeploymentTemplatePath)

$SqlDBParameterTemplatePath = "..\Templates\MainTemplate\SqlDB\SqlDBDeploymentTemplate.param.{0}.json" -f $DeploymentConfig
$SqlDBParameterTemplatePath = [System.IO.Path]::Combine($PSScriptRoot, $SqlDBParameterTemplatePath)

$SqlDBUpdatedParameterTemplatePath = "..\Templates\MainTemplate\SqlDB\SqlDBDeploymentTemplateUpdated.param.{0}.json" -f $SqlDBUpdatedParameterTemplatePath
$SqlDBUpdatedParameterTemplatePath = [System.IO.Path]::Combine($PSScriptRoot, $SqlDBUpdatedParameterTemplatePath)

<#
	.Synopsis
	Login the RM account and select subscription.
#>
function Execute-SelectSubscription{
	Login-AzureRmAccount
	Select-AzureSubscription -SubscriptionId $SubscriptionId
}

<#
	.Synopsis
	Create DB resourcegroup.
#>
function Create-DBResourceGroup{

	New-AzureRmResourceGroup -Name $DBResourceGroupName `
					   -Location $Location `
						-Force -Verbose
}

# Create or update the resource group using the specified template file and template parameters file
#Switch-AzureMode AzureResourceManager

# Action region

# Select subscription
Execute-SelectSubscription

# Create DB resource group
Create-DBResourceGroup

# Create SQL server deployment
Create-SQLServerDeployment -ParameterFilePath $TemplateParametersFile -UpdateParameterFilePath $UpdatedTemplateParametersFile -TemplateFilePath $TemplateFile

# Upgrade Sql server to version 12.0
Upgrade-SqlServer -SqlServerResourceGroupName $DBResourceGroupName -SqlServerName $SqlServerName -TargetSqlServerVersion $TargetSqlServerUpgradeVersion

# Create Sql DB deployment
Create-SqlDBDeployment -ParameterFilePath $SqlDBParameterTemplatePath -UpdateParameterFilePath $SqlDBUpdatedParameterTemplatePath -TemplateFilePath $SqlDBDeploymentTemplatePath