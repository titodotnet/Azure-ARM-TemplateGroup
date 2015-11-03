#
# SQLServerPreparation.psm1
#

Import-Module (Join-Path $PSScriptRoot "..\Common\Utility.psm1") -DisableNameChecking

$SQLServerParameterHash = New-Object -TypeName Hashtable
$DBServerDeploymentNameValue = "titotestdbserverdeploymenttest1"

<#
	.Synopsis
	Add SQL Server dynamic parameters.

	.ParameterFilePath
	Path of the Parameter file

	.UpdateParameterFilePath
	Path of the update paramter file
#>
function Add-SQLServerDynamicParams{
	
	$SqlServerInstanceParameterName = "SQLServerInstanceName"
	$SqlDbAdminUserParameterName = "SQLServerInstanceAdminLogin"
	$SqlDbAdminPasswordParameterName = "SQLServerInstanceAdminLoginPassword"
	$SqlServerLocationName = "SQLServerInstanceLocation"

	# Get DB credentials
	$DbServerAdminCredentials = Get-Credential -Message "Please enter OSE database credential"
	$SqlDbAdminPasswordSecureString = $DbServerAdminCredentials.GetNetworkCredential().Password
	
	# Add dynamic details to hash table
	$SQLServerParameterHash.Add($SqlDbAdminUserParameterName, $DbServerAdminCredentials.UserName)
	$SQLServerParameterHash.Add($SqlDbAdminPasswordParameterName, $SqlDbAdminPasswordSecureString)
	$SQLServerParameterHash.Add($SqlServerLocationName, $Location)
	$SQLServerParameterHash.Add($SqlServerInstanceParameterName, $SqlServerName)
}

<#
	.Synopsis
	Create Sql server deployment.
	
	.ParameterFilePath
	Path of the Parameter file

	.UpdateParameterFilePath
	Path of the update paramter file

	.TemplateFilePath
	Path of the template file

	.SqlServerResourceGroupName
	Name of the ResourceGroup of the respective SqlL server.
#>
function Create-SQLServerDeployment{
	[CmdletBinding()]
	param(
		[Parameter(ParameterSetName='SQLServerPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$ParameterFilePath,

		[Parameter(ParameterSetName='SQLServerPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$UpdateParameterFilePath,
		
		[Parameter(ParameterSetName='SQLServerPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$TemplateFilePath,
		
		[Parameter(ParameterSetName='SQLServerPreparation', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$SqlServerResourceGroupName	
	)
	
	$SqlServerResourceGroupInstance = Get-AzureRmResourceGroup | Where-Object {$_.ResourceGroupName -eq $SqlServerResourceGroupName}
	
	if($SqlServerResourceGroupInstance -eq $null)
	{
		Write-Output "Resource group with name '$SqlServerResourceGroupName' not available."
	}
	else
	{
		$SqlServerResourceInstance = Get-AzureRmSqlServer -ResourceGroupName $SqlServerResourceGroupName | Where-Object {$_.ServerName -eq $SqlServerName}

		if($SqlServerResourceInstance -eq $null -or ($SqlServerResourceInstance -ne $null -and $SqlServerResourceInstance.ServerVersion -eq "2.0")){
			# Prepare SQL server dynamic parameter hash
			Add-SQLServerDynamicParams

			# Create the paramter file with updated value
			Create-UpdatedParamaterTemplate -ParameterFilePath $ParameterFilePath -UpdateParameterFilePath $UpdateParameterFilePath -ParameterHash $SQLServerParameterHash

			# Perform new DBResourceGroup deployment
			New-AzureRmResourceGroupDeployment -ResourceGroupName $SqlServerResourceGroupName -Name $DBServerDeploymentNameValue -TemplateFile $TemplateFilePath -TemplateParameterFile $UpdateParameterFilePath 
		}
	}	
}

<#
	.Synopsis
	Upgrade SQL server.
	
	.SqlServerResourceGroupName
	Name of the ResourceGroup of the respective SqlL server.

	.SqlServerName
	Name of the Sql server.
#>
function Upgrade-SqlServer{
	[CmdletBinding()]
	param(
		[Parameter(ParameterSetName='SQLServerUpgrade', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$SqlServerResourceGroupName,

		[Parameter(ParameterSetName='SQLServerUpgrade', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$SqlServerName,

		[Parameter(ParameterSetName='SQLServerUpgrade', Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$TargetSqlServerVersion
	)

	$SqlServerResourceGroupInstance = Get-AzureRmResourceGroup | Where-Object {$_.ResourceGroupName -eq $SqlServerResourceGroupName}
	
	if($SqlServerResourceGroupInstance -eq $null)
	{
		Write-Output "Resource group with name '$SqlServerResourceGroupName' not available."
	}
	else
	{
		$SqlServerResourceInstance = Get-AzureRmSqlServer -ResourceGroupName $SqlServerResourceGroupName | Where-Object {$_.ServerName -eq $SqlServerName}

		if($SqlServerResourceInstance -eq $null)
		{
			Write-Output "Sql server with name '$SqlServerName' not available."
		}
		else
		{
			if($SqlServerResourceInstance.ServerVersion -eq $TargetSqlServerVersion)
			{
				Write-Output "Sql server $SqlServerName is already  with version $($SqlServerResourceInstance.ServerVersion)"
			}
			else
			{				
				$SqlServerProvisioningStatus = Get-AzureRmResourceGroupDeployment -ResourceGroupName $SqlServerResourceGroupName -Name $DBServerDeploymentNameValue
				Write-Output "Waiting for Sql Server $SqlServerName provisoning succeded... - Current state $($SqlServerProvisioningStatus.ProvisioningState)"
				While($SqlServerProvisioningStatus.ProvisioningState -ne "Succeeded" -and $SqlServerProvisioningStatus.ProvisioningState -ne "Failed")
				{
					Start-Sleep -Seconds 5	
					Write-Host -NoNewline -BackgroundColor Green "."
					$SqlServerProvisioningStatus = Get-AzureRmResourceGroupDeployment -ResourceGroupName $SqlServerResourceGroupName -Name $DBServerDeploymentNameValue								
				}

				Write-Output "Start upgrading the sql server $SqlServerName."
				Start-AzureRmSqlServerUpgrade -ServerVersion $TargetSqlServerVersion -ServerName $SqlServerName -ResourceGroupName $SqlServerResourceGroupName
				
				$SqlServerUpgradeStatus = Get-AzureRmSqlServerUpgrade -ResourceGroupName $SqlServerResourceGroupName -ServerName $SqlServerName
				Write-Output "Upgrade in progress..."
				
				While($SqlServerUpgradeStatus.Status -ne "Failed" -and $SqlServerUpgradeStatus.Status -ne "Succeeded" -and $SqlServerUpgradeStatus.Status -ne "NotStarted"){
					Start-Sleep -Seconds 5
					Write-Host -NoNewline -BackgroundColor Green "."
					$SqlServerUpgradeStatus = Get-AzureRmSqlServerUpgrade -ResourceGroupName $SqlServerResourceGroupName -ServerName $SqlServerName
				}

				Write-Output "Upgrade sql server $SqlServerName $($SqlServerUpgradeStatus.Status)."
			}			
		}		
	}	
}
