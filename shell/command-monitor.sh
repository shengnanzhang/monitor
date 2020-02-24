#/usr/bin/bash

STATUS=-1

HOSTS=('10.0.0.71' '10.0.0.72')
CMDS=('ls ~','touch aaa','mv aaa bbb','cat bbb','ps -elf','lsof -a', 'netstat -anp')

prepare()
{
    yum install -y expect
}


check_status()
{
    cmd=time -o $1
     
}

login()
{
    user="root"
    password="MXtVqY3UHzuqUUZUEmZWRYUh"
    expect -c "
    set host $1
    spawn ssh $user@$host
    expect {
       \"*password:\" {set timeout 300; send $password;}
       \"yes/no\" {send \"yes\r\"; exp_continue;}
    }
    "
}
doit()
{
    for host in ${HOSTS[@]};
    do 
        printf "$host"
        login host CMDS
        for cmd in CMDS:
        do 
            check_status cmd
        done
    done
}

prepare
doit
