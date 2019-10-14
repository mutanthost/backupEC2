#!/usr/bin/env bash
#rsync -azP source destination
echo "1. show_env Show your Environment and Database"
echo "2. restore_from_nfs to EC2 instance"
echo "3. uncompress_files from exa"
echo "4. rsync_push for pushing data to remote db from local pc"
echo "5. local_db_backup for backing up new products added in the database"
echo "6. insert_new_products_on_server for loading latest products on server"
echo "type the name of the function"
echo
read input

#remote_backup_path="/home/ubuntu/db_backup"
#local_backup_path="~/db_backup"
#db_name
#db_user
#db_pass
#backup_file
restore_from_nfs {
    echo " will write to /u01/data directory"
#    ssh -i ~/.ssh/ctestmt.pem ec2-user@$database1 
# this is just an example for a good one-liner  'cd $remote_backup_path; mysqldump -u $db_name -p$db_pass $db_name > dbname.sql; git add $backup_file; git commit -m "Backup on `date`"'
}

uncompress_files {
    echo "uncompressing files"
#    ssh -i ~/.ssh/ctestmt.pem ec2-user@$database1
# this is just an example for a good one-liner  'cd db_backup; mysql -u $db_user -p$db_pass $db_name < $backup_file'

}

show_env {
    echo
    echo "Pushing db to remote computer"
    echo
#    rsync -qrav -e 'ssh -i new.pem' ~/db_backup/ ubuntu@52.64.0.34:$remote_backup_path
} 

rsync_pull {
    echo
    echo "Your shell is"
    echo 
    echo
#    rsync -qrav -e 'ssh -i new.pem' ubuntu@52.64.0.34:$remote_backup_path $local_backup_path
} 

local_db_backup {
    echo 
    echo "backing up local db"
    echo
#    mysqldump --complete-insert=True --lock-all-tables --no-create-db --no-create-info --extended-insert=False --insert-ignore -u $db_user -p$db_pass $db_name > $local_backup_path

#    cd $local_backup_path
#    git add $db_name; git commit -m "Local Backup on `date`"
}

insert_new_products_on_server {
#    git diff HEAD^ HEAD | grep "^+" |sed 's/^+\(.*\)/\1/' > product.sql  
#    rsync -qrav -e 'ssh -i new.pem' $local_backup_path/product.sql ubuntu@52.64.0.34:$remote_backup_path
#    ssh -i new.pem ubuntu@52.64.0.34 'cd db_backup; mysql -u $db_user -p$db_pass $db_name < product.sql'
}
#insert ignore will not write duplicate values
#git diff HEAD^ HEAD | grep "^+" |sed 's/^+\(.*\)/\1/' > test.sql  = to find the added lines in a file starting with +
$input
