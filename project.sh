#!/bin/bash


#This function installing the required tools for the script
function inst()
{
#Updating and upgrading the system using the aptitude tool - this action could take long, if the user want to incloude it in script he have to uncomment it
#sudo apt update && sudo apt upgrade

#Installing the tools required for the script
sudo apt install whois 1>/dev/null && sudo apt install curl 1>/dev/null &&  sudo apt install ssh 1>/dev/null && sudo apt install sshpass 1>/dev/null
}



#This function makes sure the server is not in same lan and not in same country
function anon()
{
#Using whois too check if IP address is private and aborting if true to avoid connection in same LAN = not anonymouse/secured
ipisprivate=$(whois ${server_ip} | grep -E -q "PRIVATE-ADDRESS-[A,B,C,D,E]BLK-RFC1918-IANA-RESERVED" && echo $?)
#condition to make sure the user wants connect private IP address
if [ "$ipisprivate" == "0" ]; then
	echo -e "\e[33m WARANING! YOU ARE TRYING TO CONNECT PRIVATE IP ADDRESS\e[0m"
	read -p "Can't check remote server's origin beacause you're about to connect private IP address, you sure you want to continue? [type 'yes' to continue]: " choise
	if [ "$choise" != "yes" ]; then
		echo >&2 "Aborting"; exit 1;
	fi
fi
#Using whois service to get information about the remote IP and pull the destination country using grep, head and awk 
server_origin=$(whois ${server_ip} | grep -i Country | head -1 | awk '{print $2}')
#Using curl service to get public IP address of local PC 
localpc_IP=$(curl -s ifconfig.me)
echo "your public IP: $localpc_IP. You may want to hide it with VPN."
#Using whois service to get local PC IP's origin
localpc_origin=$(whois ${localpc_IP} | grep -i Country | head -1 | awk '{print $2}')
#Statement to compare destination IP country to local PCs country
if [ "$server_origin" == "$localpc_origin" ]; then
#If destination's ip country  equals the local PC IP, exiting the script and telling the user
	echo -e >&2 "\e[31m The connection is not anonymously! Server is in the same country. Aborting! \e[0m"; exit 1;
else
	if [ "$ipisprivate" != "0" ]; then
		echo "The remote connection is in $server_origin, and you are in $localpc_origin, it's okay"
	fi
fi
}



#This function execute the connection using sshpass- to take the password from variable in the script, and SSH to connect 
function vps()
{
$(sshpass -p $server_pass ssh -o StrictHostKeyChecking=no $full_address ${command} > stdout.txt) 
export exit_code=$?
if [ $exit_code != "0" ]; then
	$(rm stdout.txt)
	echo -e "\e[31m General error! please check the details you provided or your connection.\e[0m"; exit 1;
fi
}



echo "Please wait while updating the system and installing the required tools" 
inst #installing required tools for the script to work

#Getting input from the user - server address, server ip and server password
read -p "Please enter the remote server username: " server_uname
read -p "Please enter the remote server address: " server_ip
#a loop to check validity of IP address
while [[ !( $server_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ) ]];  do
	echo -e "\e[33m please enter valid IP address: \e[0m" >&2
	read server_ip
done
echo "Please wait while checking if the connection is secured"
anon #executes the function anon to check if the connection is anonymouse

read -s -p "Please enter the remote server password:"  server_pass
echo ""
#Combining the server username at server IP and telling the user 
full_address="$server_uname@$server_ip"
#Getting the remote command from user
read -p "Please enter the command you want to execute: " command
vps #making the connection and executing the command 
echo -e "\e[32m The command sent! showing results in 5 seconds \e[0m"
sleep 5 #sleep  above command for 5 seconds
clear #clearing the screen to make the output more readable
cat stdout.txt #showing content of output file
rm stdout.txt #deleting the output file after viewing its content
