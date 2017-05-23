#!/usr/bin/expect -f
#
# Install RSA SSH KEY with no passphrase
#

set user [lindex $argv 0]
set host [lindex $argv 1]

spawn ssh-copy-id $user@$host

expect {
    "continue" { send "yes\n"; exp_continue }
    "password:" { send "superuser\n"; exp_continue}
}
