#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE="\033[0;35m"
CYAN='\033[0;36m'
PLAIN='\033[0m'

checkroot(){
    [[ $EUID -ne 0 ]] && echo -e "${RED}Please run this script as root!${PLAIN}" && exit 1
}

checksystem() {
    if [ -f /etc/redhat-release ]; then
        release="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    fi
}

checkpython() {
    if  [ ! -e '/usr/bin/python' ]; then
        echo "Installing Python"
        if [ "${release}" == "centos" ]; then
            yum update > /dev/null 2>&1
            yum -y install python > /dev/null 2>&1
        else
            apt-get update > /dev/null 2>&1
            apt-get -y install python > /dev/null 2>&1
        fi
    fi
}

checkcurl() {
    if  [ ! -e '/usr/bin/curl' ]; then
        echo "Installing Curl"
        if [ "${release}" == "centos" ]; then
            yum update > /dev/null 2>&1
            yum -y install curl > /dev/null 2>&1
        else
            apt-get update > /dev/null 2>&1
            apt-get -y install curl > /dev/null 2>&1
        fi
    fi
}

checkwget() {
    if  [ ! -e '/usr/bin/wget' ]; then
        echo "Installing Wget"
        if [ "${release}" == "centos" ]; then
            yum update > /dev/null 2>&1
            yum -y install wget > /dev/null 2>&1
        else
            apt-get update > /dev/null 2>&1
            apt-get -y install wget > /dev/null 2>&1
        fi
    fi
}

checkspeedtest() {
    if  [ ! -e './speedtest-cli/speedtest' ]; then
        echo "Installing Speedtest-cli"
        #wget --no-check-certificate -qO speedtest.tgz https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-$(uname -m)-linux.tgz > /dev/null 2>&1
        wget --no-check-certificate -qO speedtest.tgz https://filedown.me/Linux/Tool/speedtest_cli/ookla-speedtest-1.0.0-$(uname -m)-linux.tgz > /dev/null 2>&1
    fi
    mkdir -p speedtest-cli && tar zxvf speedtest.tgz -C ./speedtest-cli/ > /dev/null 2>&1 && chmod a+rx ./speedtest-cli/speedtest
}

speed_test(){
    speedLog="./speedtest.log"
    true > $speedLog
    speedtest-cli/speedtest -p no -s $1 --accept-license --accept-gdpr > $speedLog 2>&1
    is_upload=$(cat $speedLog | grep 'Upload')
    if [[ ${is_upload} ]]; then
        local REDownload=$(cat $speedLog | awk -F ' ' '/Download/{print $3}')
        local reupload=$(cat $speedLog | awk -F ' ' '/Upload/{print $3}')
        local relatency=$(cat $speedLog | awk -F ' ' '/Latency/{print $2}')
        
        local nodeID=$1
        local nodeLocation=$2
        local nodeISP=$3
        
        strnodeLocation="${nodeLocation}　　　　　　"
        LANG=C
        
        temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
        if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
            printf "${RED}%-6s${YELLOW}%s%s${GREEN}%-24s${CYAN}%s%-10s${BLUE}%s%-10s${PURPLE}%-8s${PLAIN}\n" "${nodeID}"  "${nodeISP}" "|" "${strnodeLocation:0:24}" "↑ " "${reupload}" "↓ " "${REDownload}" "${relatency}" | tee -a $log
        fi
    else
        local cerror="ERROR"
    fi
}

preinfo() {
    echo "——————————————————————————————————————————————————————————"
    echo " SuperSpeed Full Speed Test Fix Version. By UXH & ernisn & oooldking"
    echo " Node Update: 2022/11/28 | Script Update: 2022/11/28"
    echo " Github: https://github.com/uxh/superspeed"
    echo "——————————————————————————————————————————————————————————"
}

selecttest() {
    echo -e "  Speed test type:  ${GREEN}0.${PLAIN} Cancel Test    ${GREEN}1.${PLAIN} Three-Network Test    ${GREEN}2.${PLAIN} Detailed Test"
    echo -ne "                   ${GREEN}3.${PLAIN} Telecom Nodes    ${GREEN}4.${PLAIN} Unicom Nodes    ${GREEN}5.${PLAIN} Mobile Nodes"
    while :; do echo
        read -p "  Please enter a number to select the test type: " selection
        if [[ ! $selection =~ ^[0-5]$ ]]; then
            echo -ne "  ${RED}Invalid input${PLAIN}, please enter a correct number!"
        else
            break   
        fi
    done
}

runtest() {
    [[ ${selection} == 0 ]] && exit 1

    if [[ ${selection} == 1 ]]; then
        echo "——————————————————————————————————————————————————————————"
        echo "ID    Speed Test Server Info    Upload/Mbps   Download/Mbps   Latency/ms"
        start=$(date +%s) 

        speed_test '27377' 'Beijing 5G' 'Telecom'
        speed_test '28946' 'Chongqing 5G' 'Telecom'
        # ... several speed_test calls for Telecom nodes omitted for brevity ...

        speed_test '5145'  'Beijing' 'Unicom'
        # ... several speed_test calls for Unicom nodes omitted for brevity ...

        speed_test '25858' 'Beijing' 'Mobile'
        # ... several speed_test calls for Mobile nodes omitted for brevity ...

        end=$(date +%s)  
        rm -rf speedtest*
        echo "——————————————————————————————————————————————————————————"
        time=$(( $end - $start ))
        if [[ $time -gt 60 ]]; then
            min=$(expr $time / 60)
            sec=$(expr $time % 60)
            echo -ne "  Test complete, time used: ${min} min ${sec} sec"
        else
            echo -ne "  Test complete, time used: ${time} sec"
        fi
        echo -ne "\n  Current time: "
        echo $(TZ=UTC-8 date +%Y-%m-%d" "%H:%M:%S)
        echo -e "  ${GREEN}# To avoid unequal numbers of nodes and long test time during three-network test, some nodes are not used.${PLAIN}"
        echo -e "  ${GREEN}# If you want to test all nodes, please select single-network node tests separately.${PLAIN}"
    fi

    if [[ ${selection} == 2 ]]; then
        echo "——————————————————————————————————————————————————————————"
        echo "ID    Speed Test Server Info    Upload/Mbps   Download/Mbps   Latency/ms"
        start=$(date +%s) 

        # Speed test calls with all nodes for detailed test (similar to above but all nodes included)

        end=$(date +%s)  
        rm -rf speedtest*
        echo "——————————————————————————————————————————————————————————"
        time=$(( $end - $start ))
        if [[ $time -gt 60 ]]; then
            min=$(expr $time / 60)
            sec=$(expr $time % 60)
            echo -ne "  Test complete, time used: ${min} min ${sec} sec"
        else
            echo -ne "  Test complete, time used: ${time} sec"
        fi
        echo -ne "\n  Current time: "
        echo $(TZ=UTC-8 date +%Y-%m-%d" "%H:%M:%S)
    fi

    if [[ ${selection} == 3 ]]; then
        echo "——————————————————————————————————————————————————————————"
        echo "ID    Speed Test Server Info    Upload/Mbps   Download/Mbps   Latency/ms"
        start=$(date +%s) 

        # Telecom nodes speed test calls (subset)

        end=$(date +%s)  
        rm -rf speedtest*
        echo "——————————————————————————————————————————————————————————"
        time=$(( $end - $start ))
        if [[ $time -gt 60 ]]; then
            min=$(expr $time / 60)
            sec=$(expr $time % 60)
            echo -ne "  Test complete, time used: ${min} min ${sec} sec"
        else
            echo -ne "  Test complete, time used: ${time} sec"
        fi
        echo -ne "\n  Current time: "
        echo $(TZ=UTC-8 date +%Y-%m-%d" "%H:%M:%S)
    fi

    if [[ ${selection} == 4 ]]; then
        echo "——————————————————————————————————————————————————————————"
        echo "ID    Speed Test Server Info    Upload/Mbps   Download/Mbps   Latency/ms"
        start=$(date +%s) 

        # Unicom nodes speed test calls (subset)

        end=$(date +%s)  
        rm -rf speedtest*
        echo "——————————————————————————————————————————————————————————"
        time=$(( $end - $start ))
        if [[ $time -gt 60 ]]; then
            min=$(expr $time / 60)
            sec=$(expr $time % 60)
            echo -ne "  Test complete, time used: ${min} min ${sec} sec"
        else
            echo -ne "  Test complete, time used: ${time} sec"
        fi
        echo -ne "\n  Current time: "
        echo $(TZ=UTC-8 date +%Y-%m-%d" "%H:%M:%S)
    fi

    if [[ ${selection} == 5 ]]; then
        echo "——————————————————————————————————————————————————————————"
        echo "ID    Speed Test Server Info    Upload/Mbps   Download/Mbps   Latency/ms"
        start=$(date +%s) 

        # Mobile nodes speed test calls (subset)

        end=$(date +%s)  
        rm -rf speedtest*
        echo "——————————————————————————————————————————————————————————"
        time=$(( $end - $start ))
        if [[ $time -gt 60 ]]; then
            min=$(expr $time / 60)
            sec=$(expr $time % 60)
            echo -ne "  Test complete, time used: ${min} min ${sec} sec"
        else
            echo -ne "  Test complete, time used: ${time} sec"
        fi
        echo -ne "\n  Current time: "
        echo $(TZ=UTC-8 date +%Y-%m-%d" "%H:%M:%S)
    fi
}

runall() {
    checkroot;
    checksystem;
    checkpython;
    checkcurl;
    checkwget;
    checkspeedtest;
    clear
    speed_test;
    preinfo;
    selecttest;
    runtest;
    rm -rf speedtest*
}

runall
