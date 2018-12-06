# EX236
## [root@foundation0]#
if \[ -d RH236 ]; then  
&nbsp;&nbsp;rm -rf RH236  
fi  
git clone https://github.com/suzhen99/RH236.git  
source /content/courses/rhgs/rhgs3.1/labtool.shlib  
echo y | rht-vmctl fullreset classroom  
wait_tcp_port classroom  
for i in server{a..e} workstation; do  
&ensp;&ensp;qemu-img resize /content/rhgs3.1/x86_64/vms/rh236-$i-vda.qcow2 40G >/dev/null  
&ensp;&ensp;if grep -q rh236-$i-vdb.qcow2 /content/rhgs3.1/x86_64/vms/rh236-$i.xml; then  
&ensp;&ensp;&ensp;&ensp;cp /content/rhgs3.1/x86_64/vms/rh236-$i.xml /content/rhgs3.1/x86_64/vms/rh236-$i.xml_origin  
&ensp;&ensp;&ensp;&ensp;if hostname | grep -q servera; then  
&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;sed -i '45,49d' /content/rhgs3.1/x86_64/vms/rh236-$i.xml  
&ensp;&ensp;&ensp;&ensp;else  
&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;sed -i '44,48d' /content/rhgs3.1/x86_64/vms/rh236-$i.xml  
&ensp;&ensp;&ensp;&ensp;fi  
&ensp;&ensp;fi  
done  
echo y | rht-vmctl fullreset all  
for i in server{a..d}; rht-vmctl start $i; done  
wait_tcp_port workstation  
chmod +x RH236/wp.sh  
for i in RH236/wp.sh /content/courses/rhgs/rhgs3.1/{labtool.shlib,grading-scripts/labtool.rhgs.shlib}; do  
&ensp;&ensp;scp $i root@workstation:/usr/local/sbin  
done  
ssh root@workstation 'wp.sh'  
