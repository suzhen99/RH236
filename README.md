## EX36

if [ -d RH236 ]; then
  rm -rf RH236
fi
git clone https://github.com/suzhen99/RH236.git
source /content/courses/rhgs/rhgs3.1/labtool.shlib
echo y | rht-vmctl fullreset classroom
wait_tcp_port classroom
for i in server{a..e} workstation; do
  qemu-img resize /content/rhgs3.1/x86_64/vms/rh236-$i-vda.qcow2 40G >/dev/null
  if grep -q rh236-$i-vdb.qcow2 /content/rhgs3.1/x86_64/vms/rh236-$i.xml; then
    sed -i '44,49d' /content/rhgs3.1/x86_64/vms/rh236-$i.xml
  fi 
done
echo y | rht-vmctl fullreset all
for i in server{a..d}; rht-vmctl start $i; done
wait_tcp_port workstation
chmod +x RH236/wp.sh
for i in RH236/wp.sh /content/courses/rhgs/rhgs3.1/{labtool.shlib,grading-scripts/labtool.rhgs.shlib}; do
scp $i root@workstation:/usr/local/sbin
done
ssh root@workstation 'wp.sh'
