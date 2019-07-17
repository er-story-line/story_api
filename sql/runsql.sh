#!/bin/bash

cd tables
tables=(*/)
tables=("${tables[@]%/}")
cd ../views
views=(*/)
views=("${views[@]%/}")
select_tables=("${tables[@]%/}" "${views[@]%/}" "all")
alltableops=("drop" "create" "functions" "insert" "foreignkeys")
allviewops=("drop" "createview")
cd ../

psqlCommand() {
    SQLFILE=$1
    psql --dbname=$INSTANCE_DB --host=$DB_HOST --port=$DB_PORT --username=$DB_USERNAME --set=sslmode=disable --file=$SQLFILE
}

recursiveViewCreation() {
    views=("$@")
    failstack=()
    for view in "${views[@]}"; do
        cd $view
        if [ -f createview.sql ]; then
            # errors are redirected to /dev/null since they are all eventually resolved
            # in recursive calls to this function
            psql -v ON_ERROR_STOP=1 --dbname=$INSTANCE_DB --host=$DB_HOST --port=$DB_PORT --username=$DB_USERNAME --set=sslmode=disable --file=createview.sql 2> /dev/null
            code=$?
            if [ $code == 3 ]; then
                # push view whos creation failed on to stack
                failstack+=($view)
            fi
        fi
        cd ../
    done
    if [ "${#failstack[@]}" != 0 ]; then
        # recursively call this function until all views are created
        recursiveViewCreation ${failstack[@]}
    fi
}

sqlStatement() {
    t=$1
    op=$2
    dependencies=()
    if [ "$t" == 'all' ]; then
        if [ "$op" == 'all' ]; then
            cd tables
            for thisop in "${alltableops[@]}"; do
                if [ "$thisop" == 'functions' ]; then
                    psqlCommand "../functions/updated_at.sql"
                    continue
                fi
                for table in "${tables[@]}"; do
                    cd $table
                    if [ -f $thisop.sql ]; then
                        psqlCommand $thisop.sql
                    fi
                    cd ../
                done
            done
            cd ../views
            recursiveViewCreation ${views[@]}
            cd ../
        else
            if [ "$op" == 'functions' ]; then
                psqlCommand "functions/updated_at.sql"
            else
                for table in "${tables[@]}"; do
                    doSingleOp tables/$table $op
                done
                for view in "${views[@]}"; do
                    doSingleOp views/$view $op
                done
            fi
        fi
    else
        schema_type="tables"
        if [[ " ${views[@]} " =~ " ${t} " ]]; then
            schema_type="views"
        fi
        if [ "$op" == 'all' ]; then
            if [ "${schema_type}" == "tables" ]; then
                for thisop in "${alltableops[@]}"; do
                    doSingleOp tables/$t $thisop
                done
            else
                for thisop in "${allviewops[@]}"; do
                    doSingleOp views/$t $thisop
                done
            fi
        else
            doSingleOp ${schema_type}/$t $op
        fi
    fi
}

doSingleOp() {
    path=$1
    op=$2
    pushd $path >/dev/null
    if [ -f $op.sql ]; then
        psqlCommand $op.sql
    else
        echo -e "WARNING: the file $op.sql does not exist for '$path'. Skipping..."
    fi
    popd >/dev/null
}

inform=""
command=""
while true; do
    read -p "1) Create Table(s)
2) Drop Table(s)/View(s)
3) Insert Test Data
4) Add References (foreign keys)
5) Create View(s)
6) Create Functions
7) all
q) quit
Select an operation to perform: " answer
    case $answer in
    [1]*)
        inform="Creating table(s)...\n"
        command="create"
        break
        ;;
    [2]*)
        inform="Dropping table(s)/view(s)...\n"
        command="drop"
        break
        ;;
    [3]*)
        inform="Inserting test data...\n"
        command="insert"
        break
        ;;
    [4]*)
        inform="Adding foreign key(s)...\n"
        command="foreignkeys"
        break
        ;;
    [5]*)
        inform="Creating view(s)...\n"
        command="createview"
        break
        ;;
    [6]*)
        inform="Creating function(s)...\n"
        command="functions"
        break
        ;;
    [7]*)
        inform="Performing all operations...\n"
        command="all"
        break
        ;;
    [Qq]*)
        echo -e "\nBye."
        exit
        ;;
    *) echo "Please select one of 1, 2, 3, 4, 5, 6, 7, or q" ;;
    esac
done

printf "\n"
PS3='Select a table/view or all: '
select ssel in "${select_tables[@]}"; do
    echo -e "\n"
    break
done

echo -e "$inform"
sqlStatement "$ssel" "$command"
