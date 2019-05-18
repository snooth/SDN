#!/bin/sh

apt install usb_modeswitch
#Uncomment if using in redhat/centos, comment above.
# yum install usb-modeswitch 

## Change Huawei USB modem in unix from storage adapter to lte modem
usb_modeswitch -v 12d1 -p 1f01 -M '55534243123456780000000000000011062000000101000100000000000000'
