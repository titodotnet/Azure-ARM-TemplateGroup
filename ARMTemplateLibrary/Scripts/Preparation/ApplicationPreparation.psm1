#
# ApplicationPreparation.psm1
#

Import-Module (Join-Path $PSScriptRoot "..\Common\Utility.psm1") -DisableNameChecking

$ApplicationParameterHash = New-Object -TypeName Hashtable


<#
	.Synopsis
	Add Application deployment dynamic parameters.
#>
function Add-ApplicationDeploymentDynamicParams{

	Write-Output "Preparing Application deployment dynamic params"
	
	$EnvironmentParameterName = "EnvironmentName"
	$SearchLocationParametername = "SearchLocation"

	$ApplicationParameterHash.Add($EnvironmentParameterName,$Environment)
	$ApplicationParameterHash.Add($SearchLocationParametername,$SearchServiceLocation)
}


<#
	.Synopsis
	Create Application deployment.
	
	.ParameterFilePath
	Path of the Parameter file

	.UpdateParameterFilePath
	Path of the update paramter file

	.TemplateFilePath
	Path of the template file
	
	.ApplicationResourceGroupName
	Name of the ResourceGroup of the respective SqlL server.
#>
function Create-ApplicationDeployment{
	[CmdletBinding()]
	param(
		[Parameter(ParameterSetName='SqlDBPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ParameterFilePath,

		[Parameter(ParameterSetName='SqlDBPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UpdateParameterFilePath,
		
		[Parameter(ParameterSetName='SqlDBPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$TemplateFilePath,
		
		[Parameter(ParameterSetName='SqlDBPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ApplicationResourceGroupName
	)
	
	# Prepare Sql DB dynamic parameter hash
	Add-ApplicationDeploymentDynamicParams

	# Create the paramter file with updated value
	Create-UpdatedParamaterTemplate -ParameterFilePath $ParameterFilePath -UpdateParameterFilePath $UpdateParameterFilePath -ParameterHash $ApplicationParameterHash

	# Perform new DBResourceGroup deployment for Sql DB
	New-AzureRmResourceGroupDeployment -ResourceGroupName $ApplicationResourceGroupName -Name "titotestapplicationdeploymenttest1" -TemplateFile $TemplateFilePath -TemplateParameterFile $UpdateParameterFilePath 
}