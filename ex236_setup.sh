#!/bin/bash

source /content/courses/rhgs/rhgs3.1/labtool.shlib
source /content/courses/rhgs/rhgs3.1/grading-scripts/labtool.rhgs.shlib

if [[ "${EUID}" -gt "0" ]] ; then sudo $0 "$@"; exit; fi

echo y | rht-vmctl fullreset classroom

wait_online classroom
for i in server{a..e} workstation; do
  qemu-img resize /content/rhgs3.1/x86_64/vms/rh236-$i-vda.qcow2 40G >/dev/null
  if grep -q rh236-$i-vdb.qcow2 /content/rhgs3.1/x86_64/vms/rh236-$i.xml; then
    if hostname | grep -q servera; then
      sed -i.origin '45,49d' /content/rhgs3.1/x86_64/vms/rh236-$i.xml
    else
      sed -i.origin '44,48d' /content/rhgs3.1/x86_64/vms/rh236-$i.xml
    fi
  fi
done

echo y | rht-vmctl fullreset all
for i in server{a..d}; do rht-vmctl start $i; done

wait_online workstation
for i in RH236/wp.sh /content/courses/rhgs/rhgs3.1/{labtool.shlib,grading-scripts/labtool.rhgs.shlib}; do
  scp $i root@workstation:/usr/local/sbin &>/dev/null
done
ssh root@workstation 'wp.sh'
