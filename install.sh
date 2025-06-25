#!/bin/bash

while true; do
  clear

  echo -e "\033[96m_  _ ____  _ _ _    _ ____ _  _ "
  echo "  _____        _        _____ _ _ _ _             "
  echo " |  __ \      | |      / ____| (_) | | |            "
  echo " | |__) |__ _| |_    | (___ | |_| | | |_ _ __ __ _ "
  echo " |  ___/ _\` | __|    \___ \| | | | | __| '__/ _\` |"
  echo " | | | | (_| | |_     ____) | | | | | |_| | | | (_| |"
  echo " |_|  \__,_|\__|   |_____/|_|_|_|_|\__|_|  \__,_|"
  echo -e "\033[96mFireinrain BBR v3 One-Click Script Tool v1.9 (Supports Ubuntu, Debian, CentOS)\033[0m"
  echo "------------------------"
  echo "1. System Information Query"
  echo "2. System Update"
  echo "3. System Cleanup"
  echo "4. BBR Management ▶"
  echo "5. Test Script Collection ▶ "
  echo "6. BBRv3 Installation"
  echo "------------------------"
  echo "0. Exit Script"
  echo "------------------------"
  read -p "Please enter your choice: " choice

  case $choice in
    1)
      clear
      # Function: Get IPv4 and IPv6 addresses
      fetch_ip_addresses() {
        ipv4_address=$(curl -s ipv4.ip.sb)
        ipv6_address=$(curl -s --max-time 2 ipv6.ip.sb)
      }

      # Get IP addresses
      fetch_ip_addresses

      if [ "$(uname -m)" == "x86_64" ]; then
        cpu_info=$(grep 'model name' /proc/cpuinfo | uniq | sed -e 's/model name[[:space:]]*: //')
      else
        cpu_info=$(lscpu | grep 'Model name' | sed -e 's/Model name[[:space:]]*: //')
      fi

      cpu_usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}')
      cpu_usage_percent=$(printf "%.2f" "$cpu_usage")%

      cpu_cores=$(nproc)

      mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

      disk_info=$(df -h | awk '$NF=="/"{printf "%d/%dGB (%s)", $3,$2,$5}')

      country=$(curl -s ipinfo.io/country)
      city=$(curl -s ipinfo.io/city)

      isp_info=$(curl -s ipinfo.io/org)

      cpu_arch=$(uname -m)

      hostname=$(hostname)

      kernel_version=$(uname -r)

      congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
      queue_algorithm=$(sysctl -n net.core.default_qdisc)

      # Try to get OS info using lsb_release
      os_info=$(lsb_release -ds 2>/dev/null)

      # If lsb_release fails, try other methods
      if [ -z "$os_info" ]; then
        if [ -f "/etc/os-release" ]; then
          os_info=$(source /etc/os-release && echo "$PRETTY_NAME")
        elif [ -f "/etc/debian_version" ]; then
          os_info="Debian $(cat /etc/debian_version)"
        elif [ -f "/etc/redhat-release" ]; then
          os_info=$(cat /etc/redhat-release)
        else
          os_info="Unknown"
        fi
      fi

      clear
      output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
          NR > 2 { rx_total += $2; tx_total += $10 }
          END {
              rx_units = "Bytes";
              tx_units = "Bytes";
              if (rx_total > 1024) { rx_total /= 1024; rx_units = "KB"; }
              if (rx_total > 1024) { rx_total /= 1024; rx_units = "MB"; }
              if (rx_total > 1024) { rx_total /= 1024; rx_units = "GB"; }

              if (tx_total > 1024) { tx_total /= 1024; tx_units = "KB"; }
              if (tx_total > 1024) { tx_total /= 1024; tx_units = "MB"; }
              if (tx_total > 1024) { tx_total /= 1024; tx_units = "GB"; }

              printf("Total Receive: %.2f %s\nTotal Send: %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
          }' /proc/net/dev)

      current_time=$(date "+%Y-%m-%d %I:%M %p")

      swap_used=$(free -m | awk 'NR==3{print $3}')
      swap_total=$(free -m | awk 'NR==3{print $2}')

      if [ "$swap_total" -eq 0 ]; then
          swap_percentage=0
      else
          swap_percentage=$((swap_used * 100 / swap_total))
      fi

      swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"

      echo ""
      echo "System Information Query"
      echo "------------------------"
      echo "Hostname: $hostname"
      echo "ISP: $isp_info"
      echo "------------------------"
      echo "OS Version: $os_info"
      echo "Linux Version: $kernel_version"
      echo "------------------------"
      echo "CPU Architecture: $cpu_arch"
      echo "CPU Model: $cpu_info"
      echo "CPU Cores: $cpu_cores"
      echo "------------------------"
      echo "CPU Usage: $cpu_usage_percent"
      echo "Physical Memory: $mem_info"
      echo "Virtual Memory (Swap): $swap_info"
      echo "Disk Usage: $disk_info"
      echo "------------------------"
      echo "$output"
      echo "------------------------"
      echo "Network Congestion Algorithm: $congestion_algorithm $queue_algorithm"
      echo "------------------------"
      echo "Public IPv4 Address: $ipv4_address"
      echo "Public IPv6 Address: $ipv6_address"
      echo "------------------------"
      echo "Location: $country $city"
      echo "System Time: $current_time"
      echo
      ;;

    2)
      clear

      # Update system on Debian-based systems
      if [ -f "/etc/debian_version" ]; then
          DEBIAN_FRONTEND=noninteractive apt update -y && DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
      fi

      # Update system on Red Hat-based systems
      if [ -f "/etc/redhat-release" ]; then
          yum -y update
      fi
      ;;

    3)
      clear

      if [ -f "/etc/debian_version" ]; then
          # Debian-based systems cleanup
          apt autoremove --purge -y
          apt clean -y
          apt autoclean -y
          apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
          journalctl --rotate
          journalctl --vacuum-time=1s
          journalctl --vacuum-size=50M
          apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
      elif [ -f "/etc/redhat-release" ]; then
          # Red Hat-based systems cleanup
          yum autoremove -y
          yum clean all
          journalctl --rotate
          journalctl --vacuum-time=1s
          journalctl --vacuum-size=50M
          yum remove $(rpm -q kernel | grep -v $(uname -r)) -y
      fi
      ;;

    4)
      clear
      # Check and install wget if needed
      if ! command -v wget &>/dev/null; then
          if command -v apt &>/dev/null; then
              apt update -y && apt install -y wget
          elif command -v yum &>/dev/null; then
              yum -y update && yum -y install wget
          else
              echo "Unknown package manager!"
              exit 1
          fi
      fi
      wget --no-check-certificate -O tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
      chmod +x tcpx.sh
      ./tcpx.sh
      ;;

    5)
      while true; do

        echo " ▼ "
        echo "Test Script Collection"
        echo "------------------------"
        echo "1. ChatGPT Unlock Status Check"
        echo "2. Streaming Media Unlock Test"
        echo "3. TikTok Status Check"
        echo "4. Triple ISP Return Path Latency Route Test"
        echo "5. Triple ISP Return Route Test"
        echo "6. Triple ISP Dedicated Speed Test"
        echo "7. VPS Performance Dedicated Test"
        echo "8. VPS Performance Global Test"
        echo "------------------------"
        echo "0. Return to Main Menu"
        echo "------------------------"
        read -p "Please enter your choice: " sub_choice

        case $sub_choice in
            1)
                clear
                bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
                ;;
            2)
                clear
                bash <(curl -L -s check.unlock.media)
                ;;
            3)
                clear
                wget -qO- https://github.com/yeahwu/check/raw/main/check.sh | bash
                ;;
            4)
                clear
                wget -qO- git.io/besttrace | bash
                ;;
            5)
                clear
                curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
                ;;
            6)
                clear
                bash <(curl -Lso- https://git.io/superspeed_uxh)
                ;;
            7)
                clear
                curl -sL yabs.sh | bash -s -- -i -5
                ;;
            8)
                clear
                wget -qO- bench.sh | bash
                ;;
            0)
                cd $(pwd)
                ./install.sh
                exit
                ;;
            *)
                echo "Invalid input!"
                ;;
        esac
        echo -e "\033[0;32mOperation completed\033[0m"
        echo "Press any key to continue..."
        read -n 1 -s -r -p ""
        echo ""
        clear
      done
      ;;

    6)
      clear

      if dpkg -l | grep -q 'linux-xanmod'; then
            while true; do
                  clear
                  kernel_version=$(uname -r)
                  echo "You have installed the xanmod BBRv3 kernel"
                  echo "Current kernel version: $kernel_version"

                  echo ""
                  echo "Kernel Management"
                  echo "------------------------"
                  echo "1. Update BBRv3 Kernel              2. Uninstall BBRv3 Kernel"
                  echo "------------------------"
                  echo "0. Return to previous menu"
                  echo "------------------------"
                  read -p "Please enter your choice: " sub_choice

                  case $sub_choice in
                      1)
                        apt purge -y 'linux-*xanmod1*'
                        update-grub

                        apt update -y
                        apt install -y wget gnupg

                        # Import xanmod signing key
                        wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

                        # Add repository
                        echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

                        version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

                        apt update -y
                        apt install -y linux-xanmod-x64v$version

                        echo "XanMod kernel updated. Will take effect after reboot."
                        rm -f /etc/apt/sources.list.d/xanmod-release.list
                        rm -f check_x86-64_psabi.sh*

                        reboot

                          ;;
                      2)
                        apt purge -y 'linux-*xanmod1*'
                        update-grub
                        echo "XanMod kernel uninstalled. Will take effect after reboot."
                        reboot
                          ;;
                      0)
                          break  # Exit menu
                          ;;

                      *)
                          break  # Exit menu on any other input
                          ;;

                  esac
            done
        else

          clear
          echo "Please back up data. The script will upgrade Linux kernel to enable BBRv3."
          echo "Official site: https://xanmod.org/"
          echo "------------------------------------------------"
          echo "Supports only Debian/Ubuntu and x86_64 architecture."
          echo "If VPS has 512MB RAM, please add at least 1GB swap to avoid out of memory issues!"
          echo "------------------------------------------------"
          read -p "Are you sure to continue? (Y/N): " choice

          case "$choice" in
            [Yy])
            if [ -r /etc/os-release ]; then
                . /etc/os-release
                if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
                    echo "Current environment not supported, only Debian and Ubuntu supported."
                    break
                fi
            else
                echo "Cannot determine OS type."
                break
            fi

            # Check system architecture
            arch=$(dpkg --print-architecture)
            if [ "$arch" != "amd64" ]; then
              echo "Current environment not supported, only x86_64 architecture supported."
              break
            fi

            apt update -y
            apt install -y wget gnupg

            # Import xanmod signing key
            wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

            # Add repository
            echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

            version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

            apt update -y
            apt install -y linux-xanmod-x64v$version

            # Enable BBRv3
            cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
            sysctl -p
            echo "XanMod kernel installed and BBRv3 enabled successfully. Reboot to take effect."
            rm -f /etc/apt/sources.list.d/xanmod-release.list
            rm -f check_x86-64_psabi.sh*

            # Restart SSH daemon
            systemctl restart sshd
            reboot

              ;;
            [Nn])
              echo "Cancelled"
              ;;
            *)
              echo "Invalid choice, please enter Y or N."
              ;;
          esac
        fi
        ;;
    0)
      clear
      exit
      ;;

    *)
      echo "Invalid input!"
  esac
  echo -e "\033[0;32mOperation completed\033[0m"
  echo "Press any key to continue..."
  read -n 1 -s -r -p ""
  echo ""
  clear
done
