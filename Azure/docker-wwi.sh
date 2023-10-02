#!/bin/bash
# docker-wwi.sh From https://gist.github.com/alextercete/422a0965c1c9c66b1ea0235d1dd66368
# See: https://docs.microsoft.com/en-us/sql/linux/tutorial-restore-backup-in-sql-server-container
# Used in https://www.cathrinewilhelmsen.net/sql-server-2019-docker-container/

SA_PASSWORD=<YourStrong!Passw0rd>

function show_info {
    tput setaf 6; echo $1; tput sgr 0
}

show_info 'Pulling the container image...'
sudo docker pull microsoft/mssql-server-linux:2017-latest

show_info 'Running the container image...'
sudo docker run -e 'ACCEPT_EULA=Y' -e "MSSQL_SA_PASSWORD=$SA_PASSWORD" \
   --name 'sql1' -p 1401:1433 \
   -v sql1data:/var/opt/mssql \
   -d microsoft/mssql-server-linux:2017-latest

show_info 'Copying the backup into the container...'
sudo docker exec -it sql1 mkdir -p /var/opt/mssql/backup
curl -L -o wwi.bak 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak'
sudo docker cp wwi.bak sql1:/var/opt/mssql/backup

show_info 'Restoring the database...'
sudo docker exec -it sql1 /opt/mssql-tools/bin/sqlcmd \
   -S localhost -U SA -P "$SA_PASSWORD" \
   -Q 'RESTORE DATABASE WideWorldImporters FROM DISK = "/var/opt/mssql/backup/wwi.bak" WITH MOVE "WWI_Primary" TO "/var/opt/mssql/data/WideWorldImporters.mdf", MOVE "WWI_UserData" TO "/var/opt/mssql/data/WideWorldImporters_userdata.ndf", MOVE "WWI_Log" TO "/var/opt/mssql/data/WideWorldImporters.ldf", MOVE "WWI_InMemory_Data_1" TO "/var/opt/mssql/data/WideWorldImporters_InMemory_Data_1"'

show_info 'Cleaning up...'
rm wwi.bak

show_info 'Done!'