#
# SqlDBPreparation.psm1
#

Import-Module (Join-Path $PSScriptRoot "..\Common\Utility.psm1") -DisableNameChecking

$SqlDBParameterHash = New-Object -TypeName Hashtable

<#
	.Synopsis
	Add Sql DB dynamic parameters.

	.ParameterFilePath
	Path of the Parameter file

	.UpdateParameterFilePath
	Path of the update paramter file
#>
function Add-SqlDBDynamicParams{
	
	Write-Output "Preparing Sql DB dynamic parameters"

	$SqlServerInstanceParameterName = "SQLServerInstanceName"
	$SqlServerLocationName = "SQLServerInstanceLocation"
	$SqlDbAdminUserParameterName = "SQLServerInstanceAdminLogin"
	$SqlDbAdminPasswordParameterName = "SQLServerInstanceAdminLoginPassword"
	$EnvironmentParameterName = "EnvironmentName"
		
	# Add dynamic details to hash table
	$SqlDBParameterHash.Add($SqlServerLocationName, $Location)
	$SqlDBParameterHash.Add($SqlServerInstanceParameterName, $SqlServerName)
	$SqlDBParameterHash.Add($EnvironmentParameterName, $Environment)
	$SqlDBParameterHash.Add($SqlDbAdminUserParameterName, $DbServerAdminCredentials)
	$SqlDBParameterHash.Add($SqlDbAdminPasswordParameterName, $SqlDbAdminPasswordSecureString)
}

<#
	.Synopsis
	Create Sql DB deployment.
	
	.ParameterFilePath
	Path of the Parameter file

	.UpdateParameterFilePath
	Path of the update paramter file

	.TemplateFilePath
	Path of the template file
	
	.SqlDBResourceGroupName
	Name of the ResourceGroup of the respective SqlL server.
#>
function Create-SqlDBDeployment{
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
		$SqlDBResourceGroupName
	)
	
	# Prepare Sql DB dynamic parameter hash
	Add-SqlDBDynamicParams

	# Create the paramter file with updated value
	Create-UpdatedParamaterTemplate -ParameterFilePath $ParameterFilePath -UpdateParameterFilePath $UpdateParameterFilePath -ParameterHash $SqlDBParameterHash

	# Perform new DBResourceGroup deployment for Sql DB
	New-AzureRmResourceGroupDeployment -ResourceGroupName $SqlDBResourceGroupName -Name "titotestsqldbdeploymenttest1" -TemplateFile $TemplateFilePath -TemplateParameterFile $UpdateParameterFilePath 
}