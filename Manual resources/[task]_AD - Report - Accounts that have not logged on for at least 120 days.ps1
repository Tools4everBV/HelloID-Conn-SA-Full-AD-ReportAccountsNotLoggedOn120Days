$exportReport = $form.exportReport
try {
    if($exportReport -eq "True") {
        ## export file properties
        if($HIDreportFolder.EndsWith("\") -eq $false){
            $HIDreportFolder = $HIDreportFolder + "\"
        }
        
        $timeStamp = $(get-date -f yyyyMMddHHmmss)
        $exportFile = $HIDreportFolder + "Report_AD_AccountsNotLoggedOn120Days_" + $timeStamp + ".csv"
        
        ## Report details
        $lastDate = (Get-Date).AddDays(-120)
        $filter = {lastLogon -le $lastDate}
        $properties = "CanonicalName", "Displayname", "UserPrincipalName", "SamAccountName", "Department", "Title", "Enabled", "LastLogonDate"
    
        $ous = $ADusersReportOU | ConvertFrom-Json
        $result = foreach($item in $ous) {
            Get-ADUser -Filter $filter -SearchBase $item.ou -Properties $properties
        }
        $resultCount = @($result).Count
        $result = $result | Sort-Object -Property Displayname
        
        ## export details
        $exportData = @()
        if($resultCount -gt 0){
            foreach($r in $result){
                $exportData += [pscustomobject]@{
                    "CanonicalName" = $r.CanonicalName;
                    "Displayname" = $r.Displayname;
                    "UserPrincipalName" = $r.UserPrincipalName;
                    "SamAccountName" = $r.SamAccountName;
                    "Department" = $r.Department;
                    "Title" = $r.Title;
                    "Enabled" = $r.Enabled;
                    "LastLogonDate" = $r.LastLogonDate;
                }
            }
        }
        
        $exportCount = @($exportData).Count
        Write-Information "Export row count: $exportCount"
        
        $exportData = $exportData | Sort-Object -Property productName, userName
        $exportData | Export-Csv -Path $exportFile -Delimiter ";" -NoTypeInformation
        
        Write-Information "Report [$exportFile] containing $exportCount records created successfully"
        $Log = @{
            Action            = "Undefined" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Report [$exportFile] containing $exportCount records created successfully" # required (free format text) 
            IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $exportFile # optional (free format text) 
            TargetIdentifier  = "" # optional (free format text) 
        }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log    
    }
} catch {
    Write-Error "Error generating report. Error: $($_.Exception.Message)"
    $Log = @{
        Action            = "Undefined" # optional. ENUM (undefined = default) 
        System            = "ActiveDirectory" # optional (free format text) 
        Message           = "Error generating report [$exportFile]" # required (free format text) 
        IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $exportFile # optional (free format text) 
        TargetIdentifier  = "" # optional (free format text) 
    }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log
}
