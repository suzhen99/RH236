#!/bin/bash
source /usr/local/sbin/labtool.shlib
source /usr/local/sbin/labtool.rhgs.shlib
function wp_io {
#removing CA
  CAGROUP=pkica
  CADIR=/etc/pki/CA
  SSLCONF=/etc/pki/tls/openssl.cnf
  rm -f /var/ftp/pub/{EXAMPLE-CA-CERT,example-ca.crt}
  rm -f /etc/pki/tls/certs/example-ca.crt
  rm -rf $CADIR/*
  chgrp root $CADIR
  ( umask 077; mkdir /etc/pki/CA/private )
  if [ -e $SSLCONF-glsorig ]; then
         mv -f $SSLCONF-glsorig $SSLCONF
  fi  
  getent group $CAGROUP > /dev/null && groupdel $CAGROUP
  # add custom group pkica, and add apache to the group
  getent group $CAGROUP > /dev/null || groupadd --system $CAGROUP
  (id -Gn apache | grep -q $CAGROUP) || usermod -aG $CAGROUP apache
  # set up /etc/pki/CA to be group owned and sgid for pkica group
  chgrp -R $CAGROUP $CADIR
  find $CADIR -type d | xargs chmod g+rwxs
  # basic customization
  # allow group to read
  umask 002 
  if [ -e $SSLCONF -a ! -e $SSLCONF-glsorig ]; then
          cp -f $SSLCONF $SSLCONF-glsorig
  fi  
  mkdir $CADIR/{certs,crl,newcerts} &>/dev/null
  touch $CADIR/index.txt
  touch $CADIR/serial
  echo 01 > $CADIR/serial
  # Generate CA certificate and private key.
  # ADD: -days 365 (default was 30, which has been an issue at times)
  ( cd $CADIR; openssl req -days 365 -new -x509 -nodes -out example-ca.crt -keyout private/cakey.pem \
-subj '/C=US/ST=North Carolina/L=Raleigh/O=Example, Inc./CN=lab.example.com Certificate Authority' ) &> /dev/null
 # Copy public CA files into place
  cp /etc/pki/CA/example-ca.crt /etc/pki/tls/certs
  cp /etc/pki/CA/example-ca.crt /etc/pki/CA/cacert.pem
  chmod 644 /etc/pki/tls/certs/example-ca.crt
  mkdir -p /var/ftp/pub &> /dev/null
  cp /etc/pki/CA/example-ca.crt /var/ftp/pub/glusterfs.ca
  cp /etc/pki/CA/example-ca.crt /var/ftp/pub/example-ca.crt
  # CA certificate it trusts, which may be useful in future labs.
  ln /var/ftp/pub/example-ca.crt /var/ftp/pub/EXAMPLE-CA-CERT &> /dev/null
  chmod 644 /var/ftp/pub/EXAMPLE-CA-CERT
          # Modify the index and serial file permissions so that the
          # upload_csr cgi works 
          chmod 660 $CADIR/index.txt
          chmod 660 $CADIR/serial
  # Add some ACLs so that isntructor signing by hand don't mess up
          # our glorious infrastructure
  setfacl -R -m g:pkica:rw ${CADIR}
  setfacl -m d:g:pkica:rw ${CADIR}
  #pad ' · Enabling FTP for access to certs'
  yum -y install vsftpd &> /dev/null
  systemctl enable vsftpd &> /dev/null
  systemctl start vsftpd &> /dev/null
  firewall-cmd --permanent --zone=trusted --add-service=ftp &> /dev/null
  firewall-cmd --zone=trusted --add-service=ftp &> /dev/null
  cp /etc/pki/tls/certs/example-ca.crt /etc/pki/tls/certs/glusterfs.ca
  cp /etc/pki/tls/certs/glusterfs.ca /etc/ssl/glusterfs.ca
AGROUP=pkica
openssl req -new -nodes -out /var/ftp/pub/wk.csr -keyout /var/ftp/pub/wk.key \
-subj '/C=US/ST=North Carolina/L=Raleigh/O=Example, Inc./CN=workstation.lab.example.com' &> /dev/null
openssl ca -batch -in /var/ftp/pub/wk.csr -out /var/ftp/pub/wk.crt &> /dev/null
  ( cat /var/ftp/pub/wk.key; echo; cat /var/ftp/pub/wk.crt ) > /var/ftp/pub/wk.pem
  cp /var/ftp/pub/wk.pem /etc/ssl/glusterfs.pem
  cp /var/ftp/pub/wk.key /etc/ssl/glusterfs.key
  for i in {a..e};do 
openssl req -new -nodes -out /var/ftp/pub/server${i}.csr -keyout /var/ftp/pub/server${i}.key \
-subj "/C=US/ST=North Carolina/L=Raleigh/O=Example, Inc./CN=server${i}.lab.example.com" &> /dev/null
    openssl ca -batch -in /var/ftp/pub/server${i}.csr -out /var/ftp/pub/server${i}.crt &> /dev/null
  ( cat /var/ftp/pub/server${i}.key; echo; cat /var/ftp/pub/server${i}.crt ) > /var/ftp/pub/server${i}.pem;
  done
pad " · Verifying certs and key for servera"
setup_command workstation "ls -l /var/ftp/pub/servera*"
pad " · Verifying certs and key for serverb"
setup_command workstation "ls -l /var/ftp/pub/serverb*"
pad " · Verifying certs and key for serverc"
setup_command workstation "ls -l /var/ftp/pub/serverc*"
pad " · Verifying certs and key for serverd"
setup_command workstation "ls -l /var/ftp/pub/serverd*"
pad " · Verifying certs and key for servere"
setup_command workstation "ls -l /var/ftp/pub/servere*"
pad " · Verifying glusterfs.ca"
setup_command workstation "ls -l /var/ftp/pub/glusterfs.ca*"
}
function ovirt_command {
  local TARGET
  TARGET="$1"
  COMMAND="$2"
  if ssh -t ${TARGET} "${COMMAND}" &> /dev/null
  then
    print_SUCCESS
  else
    print_FAIL
  fi  
}
function wp_nagios {
  host_reachable manager
  pad " · Uploading rhel6.7 repo"
  setup_command manager "curl http://materials.example.com/rhgs-rhel6.repo -o /etc/yum.repos.d/rhgs-rhel6.repo" 
  pad " · Uploading RHSC configuration file"
  setup_command manager "curl http://materials.example.com/rhsc-install.conf -o /root/rhsc-install.conf" 
  
###temp
  run_command manager "chmod 775 /root/rhsc-install.conf"
 
  pad " · Installing RHSC: This will take awhile, to view installation progress, open a terminal and run tail -f /var/log/yum.log"
  setup_command manager "yum -y install rhsc"
  pad " · Running rhsc-setup ...please be patient"
  ovirt_command manager " cat <(echo "Ok") | rhsc-setup --config-append=rhsc-install.conf"
  pad " · Configuring .ovirtshellrc for passwordless connect"
  setup_command manager "curl http://materials.example.com/.ovirtshellrc -o /root/.ovirtshellrc"
  pad ' · Creating gluster-cluster'
  ovirt_command manager "rhsc-shell -c -l  connect --url 'https://172.25.250.8/api' --user admin@internal  --insecure -E 'add cluster --name gluster-cluster --datacenter-name Default --gluster_service True --virt_service False --version-major 3 --version-minor 5'"
  pad ' · Adding host servera'
  ovirt_command  manager "rhsc-shell -c -l  connect --url 'https://172.25.250.8/api' --user admin@internal  --insecure -E  'add host --name servera --address servera.lab.example.com --root_password redhat --cluster-name gluster-cluster'"
  pad ' · Adding host serverb'
  ovirt_command  manager "rhsc-shell -c -l  connect --url 'https://172.25.250.8/api' --user admin@internal  --insecure -E  'add host --name serverb --address serverb.lab.example.com --root_password redhat --cluster-name gluster-cluster'"
  pad " · removing old version of sendmail"
  setup_command manager "yum -y remove sendmail"
  
  pad " · Installing sendmail and sendmail.cf"
  setup_command manager "yum -y install sendmail sendmail-cf"
}
function wp_target {
dd if=/dev/zero of=/file1.sda bs=6M count=100
dd if=/dev/zero of=/file2.sda bs=6M count=100
yum -y install target*
targetcli /backstores/fileio create b1 /file1.sda
targetcli /iscsi create iqn.1994-05.com.redhat:w1
targetcli /iscsi/iqn.1994-05.com.redhat:w1/tpg1/luns create /backstores/fileio/b1
targetcli /iscsi/iqn.1994-05.com.redhat:w1/tpg1/acls create iqn.1994-05.com.redhat:c6a52446f42e
targetcli /backstores/fileio create b2 /file2.sda
targetcli /iscsi create iqn.1994-05.com.redhat:w2
targetcli /iscsi/iqn.1994-05.com.redhat:w2/tpg1/luns create /backstores/fileio/b2
targetcli /iscsi/iqn.1994-05.com.redhat:w2/tpg1/acls create iqn.1994-05.com.redhat:c6a52446f42e
systemctl restart target
systemctl enable target
firewall-cmd --zone=trusted --permanent --add-port=3260/tcp
firewall-cmd --reload
}
wp_io
wp_nagios
wp_target
