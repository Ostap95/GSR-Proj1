#!/usr/bin/expect -f
#
# Connect to adminPC with no passphrase
#
spawn scp ca.crt adminPC.crt adminPC.key root@192.168.106.2:~

expect {
    "continue" { send "yes\n"; exp_continue }
    "password:" { send "root\n"; exp_continue}
}
