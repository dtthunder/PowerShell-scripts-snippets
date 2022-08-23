#Start loop with initial execution of script.
DO{
#Look for files older than 90 days in Prod and Non-Prod backup repository and dispaly the number of files.
$90_Days_Old = $(Get-Date).AddDays(-90)
$files = ""
$files = Get-childitem "\\10.179.249.230\vmprod$" -Recurse | where{($_.LastWriteTime -le $90_Days_Old)}
$files += Get-childitem "\\10.179.249.230\VMnonProd$" -Recurse | where{($_.LastWriteTime -le $90_Days_Old)}
$files = $files | sort

write-host "File Count Start of script: $($files.Count)"

$NumOfFiles = 0

#Check for TooLongNameFiles.csv and delete if found, then rebuild csv file.
IF(Test-Path S:\Library\TooLongNameFiles.csv){
        Remove-Item S:\Library\TooLongNameFiles.csv

        "Name,LastWriteTime,Directory" | Out-File S:\Library\TooLongNameFiles.csv
    }

#Start loop to iterate through each file
ForEach($File in $Files){
    #check file mode
    IF($File.mode -like "*a*"){
        $NumOfFiles++

        #Try/Catch block attempts to delete the file, if that fails, log the file name, Last write time and directory to TooLongNameFiles.csv
        TRY{
               "$($file.fullname)" | Remove-Item  -Recurse -Force -Verbose -ErrorAction stop
               Write-host ""$($file.fullname)" | Remove-Item  -Recurse -Force -Verbose"
               #pause
           }
           
        CATCH{
               Write-Output "Could not delete $($file.fullname)"
               "$($File.name),$($File.LastWriteTime),$($File.DirectoryName)" | Out-File S:\Library\TooLongNameFiles.csv -Append
               
               #inside catch, start Try/Catch block to attempt to rename the folder directly above the files to be deleted with a single character name.
               TRY{
                   Rename-Item -Path $File.Directory -NewName 1 -force -Verbose -ErrorAction stop

                   write-host "Rename-Item -Path $($File.Directory) -NewName 1 -force -Verbose"

                   $ModFolder = $File.DirectoryName
                   $ModfolderSplit = $Modfolder.split('\')
                   $ModfullPath = "\\$($ModfolderSplit[2])\$($ModfolderSplit[3])\$($ModfolderSplit[4])"

                   $newPath = "$ModfullPath\1"

                   #Try to delete file from new filepath
                   TRY{
                    Remove-Item $newPath -Recurse -Force -Verbose
                   }
                    catch{Write-Host "Could not delete file $newpath"}#>
                    #pause
                    
               }
               CATCH{Write-Host "Could not rename $($File.DirectoryName) to $newpath";"$($File.DirectoryName),$newpath" | out-file S:\Library\VRangerFilesToBeDeleted.csv -append }

               
             }

        }
        
    }

$90_Days_Old = $(Get-Date).AddDays(-90)
$files = ""
$files = Get-childitem "\\10.179.249.230\vmprod$" -Recurse | where{($_.LastWriteTime -le $90_Days_Old)}
$files += Get-childitem "\\10.179.249.230\VMnonProd$" -Recurse | where{($_.LastWriteTime -le $90_Days_Old)}
$files = $files | sort

write-host "File Count end of script: $($files.Count)"

}WHILE($NumOfFiles -gt 0)

#Get directories
$tdcs="\\10.179.249.230\vmprod$","\\10.179.249.230\VMnonProd$"

#Loop to find empty directoies and delete them
do {
ForEach($tdc in $tdcs){
    $dirs = gci $tdc -directory -recurse | Where { (gci $_.fullName).count -eq 0 } | select -expandproperty FullName
    $dirs | Foreach-Object { Remove-Item $_ -Verbose}
    }
} while ($dirs.count -gt 0)

