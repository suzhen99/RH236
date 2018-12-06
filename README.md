# RHGS3.1-1.r41468.1-2016-06-17
## [kiosk@foundation0]$
``` bash
if [ -d RH236 ]; then rm -rf RH236; fi
git clone https://github.com/suzhen99/RH236.git

chmod +x RH236/*.sh
RH236/ex236_setup.sh
  
```
