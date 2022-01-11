$arg0 = $args[0]
$arg1 = $args[1]

function init {
	if (dockerIsRunning){
        dispatcher $arg0 $arg1
        2exit	
	}
	else {
		Write-Host "Please Start and/or install Docker"
		Start-Sleep -Seconds 5
		2exit
	}	

}

function dispatcher($arg0, $arg1) {
    switch ($arg0)
    {
        "gui" {menu}
        "start" {2start}
        "restart" {restart}
        "stop" {stop}
        {($_ -eq "remove") -or ($_ -eq "rm")} {remove}
        {($_ -eq "update") -or ($_ -eq "upgrade")} {update}
        "restore" {restore}
        "setup" {startSetup}
        {($_ -eq "subl") -or ($_ -eq "text") -or ($_ -eq "sublime")} {startSoftware "subl"}
        "merge" {startSoftware "merge"}
        "gitkraken" {startSoftware "gitkraken"}
        "pycharm" {startSoftware "pycharm"}
        {($_ -eq "logs") -or ($_ -eq "log") -or ($_ -eq "l")} {viewLogs "$arg1"}
        {($_ -eq "api") -or ($_ -eq "ram") -or ($_ -eq "2nform") -or ($_ -eq "report")} {injectCommand "cd /var/www/html/$arg0" "$arg1"}
        {($_ -eq "db-functions") -or ($_ -eq "agol-scripts")} {injectCommand "cd /var/www/python/$arg0" "$arg1"}
        "help" {help}
        default {shell}
    }
}

function shell{
    if (2up) {
        Clear-Host
        docker exec -it 2nform zsh
        Clear-Host
    }
    else {
        menu
    }

}

function startSoftware($name) {
    2up
    docker exec 2nform $name
    
}

function viewLogs($type) {
    if ($type) {
        docker exec -it 2nform tail -f /var/log/2nform/$type.log
    }
    else {
        docker logs -f 2nform
    }
}

function injectCommand($arg0, $arg1) {
    docker exec -it 2nform zsh -c "$arg0 && zsh"
}

function startSetup {
    Write-Host "Starting Setup.."
    $runCommand = getConfig
    if ($runCommand){
        Write-Host "Run Command Found in Config File"
        Write-Host $runCommand
        if (yesno("Would you like to use it?")) {
            run
        }
        else {
            createRunCommand
            run
        }
    }
    else {
        createRunCommand
        run
    }
}

function createRunCommand {

    Write-Host "==== Run Command Creation ===="
    Write-Host " "
    $ports = ports
    $volumes = volumes
    $gits = gits

    $runCommand = "docker run -d --restart unless-stopped $ports $volumes $gits -h 2nform --name 2nform 2nform/docker-local-dev:latest"
    saveConfig($runCommand)
}

function ports {
    Write-Host "--- Ports : HOST:CONTAINER ---"
    Write-Host "Select ports to forward. Like:'1 3 4 5'"
    Write-Host "Leave Blank For Defaults.  (All LISTED)"
    Write-Host "----------------------------------------"
    Write-Host "1)      80:80       -Main HTTP"
    Write-Host "2)   15432:5432     -Postgres for Dbeaver"
    Write-Host "3)    9003:9003     -PHP XDebug"
    Write-Host "4)   35729:35729    -Chrome Live Reload"
    Write-Host "5)    3000:3000     -Node Api"
    Write-Host "6)    5000:5000     -Python Flask"
    Write-Host "----------------------------------------"
    $sel = Read-Host "Space Seperated Numbers : Blank for defaults"
    if ($sel) {
        $selArray = $sel.Split(" ")
        $ports = @()
        Foreach ($i in $selArray)
        {
            switch ($i)
            {
                1 {$ports = $ports + '-p 80:80'}
                2 {$ports = $ports + '-p 15432:5432'}
                3 {$ports = $ports + '-p 9003:9003'}
                4 {$ports = $ports + '-p 35729:35726'}
                5 {$ports = $ports + '-p 3000:3000'}
                6 {$ports = $ports + '-p 5000:5000'}
            }
        }
    }
    else {
        $ports = @('-p 80:80', '-p 15432:5432', '-p 9003:9003', '-p 35729:35726', '-p 3000:3000', '-p 5000:5000')
    }

    $portsString = $ports -join ' '
    return $portsString
}

function volumes {
    Write-Host "----- Volumes ------"
    $vols = @()
    if (yesno("Will you be using VS Code remote container access? (setup volume for project dir)")) {
        $vols = $vols + '-v 2nform:/var/www'
    }
    else {
        if (yesno("Would you like to use your home directory for your project folder? ($HOME\2nform)") ){
            $vols = $vols + "-v $HOME\2nform:/var/www"
        }
        else {
            Write-Host "Enter the full path for your project folder:"
            $projFolder = Read-Host "like : '$HOME\2nform'"
            $vols = $vols + "-v ${projFolder}:/var/www"
        }
    }

    if (yesno("Do you want to use you home directory for the database dump folder?")) {
        $vols = $vols + "-v $HOME/dump:/dump"
    }
    else {
        Write-Host "Enter the full path for your dump folder:"
        $dumpFolder = Read-Host "like : '$HOME\dump'"
        $vols = $vols + "-v ${dumpFolder}:/dump"
    }

    $vols = $vols + "-v postgres-data:/var/lib/postgresql"
    $vols = $vols + "-v user-data:/root"

    $volsString = $vols -join ' '
    return $volsString
}

function gits {
    Write-Host "------ Git ------"
    $gits = @()
    $username = Read-Host "Enter your Git Username:"
    $gits = $gits + "-e GIT_USERNAME=$username"
    $email = Read-Host "Enter yout Git Email:"
    $gits = $gits + "-e GIT_EMAIL=$email"

    if (yesno("Do you want to clone with SSH? (recommended)")) {
        Write-Host "You will need to add your ssh key to github.  See the main menu after setup is complete."
        Start-Sleep -s 3
    }
    else {
        $password = Read-Host "Enter your Git Password or Personal Access Token:"
        $gits = $gits + "-e GIT_PASSWORD=$password"
    }

    $gitsString = $gits -join ' '
    return $gitsString


}


function menu {
    Write-Host "MENU"
}


function run {
    if (exists) {
        Write-Host "Container Already Exists"
    }
    else {
        $runCommand = getConfig
        if ($runCommand){
            if (Invoke-Expression "$runCommand") {
                Write-Host "Container Running"
            }
            else {
                Write-Host "================================================================="
                Write-Host "There could be an issue with your run command. (See above error)"
                Write-Host " "
                Write-Host "$runCommand"
                Write-Host " "
                Write-Host "Re-form the command and update $HOME\.2nform.conf or re-run setup. ('n setup')"
                Write-Host "================================================================="
            }
        }
        else {
            if (yesno "Run Command not Found.  Create it?") {
                startSetup
            }
            else {
                Write-Host "Run Aborted"
            }
        }
    }
}

function yesno($msg){
    $read = Read-Host "$msg Y/n"
    switch -wildcard ($read.ToLower())
    {
        "n*" {return $false}
        default {return $true}
    }

}

function restart {
    if (exists) {
        if (running) {
            stop
            2start
        }
        else {
            2start
        }
    }
}

function 2start {
    if (exists) {
        if (running) {
            Write-Host "Already Running"
        }
        else {
            docker start 2nform
            Write-Host "Container Started"
        }
    }
}

function stop {
    if (exists) {
        if (running) {
            docker stop 2nform
            Write-Host "Container Stopped"
        }
    }
}

function remove {
    if (exists) {
        if (getConfig) {
            if (running) {
                stop
            }
            docker rm 2nform
            Write-Host "Container Removed" 
        }
        else {
            if (yesno("No Run Command Configured.  Remove anyway?  (You will need to re-form a run command!)")){
                if (running) {
                    stop
                }
                docker rm 2nform
                Write-Host "Container Removed"
            }
            else {
                if (yesno("Would you like to start setup now?")){
                    setup
                }
            }
        }

    }

}

function restore {
    2up
    if (yesno("Do you have ONE .backup file in your dump folder?")){
        Write-Host "Starting Restore:  This will take a while!"
        docker exec -it 2nform restore
        Write-Host "Database Restored"
    }
}

function update {
    Write-Host "Updating..."
    remove
    run
}

function reset {
    if (yesno("Are you sure?  this will remove all data!  (2nform, postgres-data, and user-data volumes)")){

        Write-Host "Resetting..."
        remove
        docker volume rm 2nform
        docker volume rm postgres-data
        docker volume rm user-data
        run
    }
}


function dockerIsRunning {
	if (Get-Process 'com.docker.proxy') {
		return $true
	}
	else {
		Write-Host "Docker Not Running or Not Installed"
		return $false
	}
}

function getConfig {
    $filePath = "$HOME\.2nform.conf"
    if (Test-Path -Path $filePath -PathType Leaf) {
        $runCommand = Get-Content -Path "$HOME\.2nform.conf"
        return $runCommand
    }
    else {
        Write-Host "No Config"
        New-Item $filePath
        Write-Host "Created Empty Config"
        return getConfig
    }
    
}

function saveConfig($runCommand) {
    $filePath = "$HOME\.2nform.conf"
    Write-Host "$runCommand"
    Set-Content $filePath $runCommand
    Write-Host "Saved Run Command"
}

function 2up {
    if (exists) {
        if (running) {
                return $true
        }
        else {
            if (yesno("Container not running.  Would you like to start it?")) {
                2start
                return $false
            }
        }
    }
    else {
        if (yesno("Container doesn't exist.  Would you like to create it?")) {
            run
            return $false
        } 
    }
}

function running {
    if (exists) {
        if (docker ps | Select-String "2nform"){
            return $true
        }
        else {
            return $false
        }
    }
}

function exists {
    if (docker ps -a | Select-String "2nform"){
        return $true
    }
    else {
        return $false
    }
}

function 2exit {
	Write-Host "- DONE -"
    Write-Host "---------------------"
    Write-Host " "
}

function help {
   Write-Host "2nform - Docker for Local Dev - Manager"
   Write-Host "----------------------------------------" 
   Write-Host "Run 'n' alone for docker shell. (starts setup if container down)"
   Write-Host "Run 'n gui' for gui manager."
   Write-Host
   Write-Host "Direct Command Reference"
   Write-Host "Syntax: n command sub-command"
   Write-Host "ex: 'n restart' or 'n api test'"
   Write-Host
   Write-Host "Commands:"
   Write-Host "===================================================="
   Write-Host "start                              Start 2nform Container"
   Write-Host "restart                            Restart 2nform Container"
   Write-Host "stop                               Stop 2nform Container"
   Write-Host "remove|rm                          Remove 2nform Container (Data Persists)"
   Write-Host
   Write-Host "restore                            Start Database Restore"
   Write-Host
   Write-Host "update|upgrade                     Update Container  (Data Persists)"
   Write-Host "reset                              Reset Container  (Data in volumes lost)"
   Write-Host
   Write-Host "text|subl|sublime                  Start Sublime Text"
   Write-Host "merge                              Start Sublime Merge"
   Write-Host "gitkraken                          Start Git Kraken"
   Write-Host "pycharm                            Start Pycharm"
   Write-Host  
   Write-Host "logs|log|l                         Open Container Logs"
   Write-Host "  -  git                           Open Git Cloner Logs"
   Write-Host "  -  restore                       Open DB Restore Logs"
   Write-Host "  -  REPO (api|ram|...)            Open Project Setup Logs"
   Write-Host
   Write-Host "REPO (api|ram|...)                 Open Project Folder in Shell"
   Write-Host
}

init($arg0, $arg1)