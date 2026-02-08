#!/bin/bash
# Written by Vasyl T. — script module for detecting installed hosting panel
# This module is used by backup.sh to load the correct backup handler

detect_panel() {

    # cPanel / WHM
    if [[ -e /usr/local/cpanel/bin/whmapi1 ]]; then
        echo "cpanel"
        return
    fi

    # DirectAdmin
    if [[ -e /usr/local/directadmin/directadmin ]]; then
        echo "directadmin"
        return
    fi

    # HestiaCP
#    if [[ -e /usr/local/hestia/bin/v-change-sys-ip-helo ]]; then

     if [[ -d /usr/local/hestia ]]; then
        echo "hestia"
        return
    fi

    # ISPmanager v5/v6
    if [[ -e /usr/local/mgr5/sbin/mgrctl ]]; then
        echo "ispmanager"
        return
    fi

    # ISPmanager 4
    if [[ -e /usr/local/ispmgr/bin/ispmgr ]]; then
        echo "ispmanager4"
        return
    fi

    # VestaCP
    if [[ -e /usr/local/vesta/bin/v-update-sys-queue ]]; then
        echo "vesta"
        return
    fi

    # BitrixVM
    if [[ -d /home/bitrix ]]; then
        echo "bitrix"
        return
    fi

    # No known panel detected
    echo "none"
}
#detect_panel
