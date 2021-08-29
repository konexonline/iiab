#!/bin/bash

# SEE ALSO: /etc/profile.d/sshpwd-profile-iiab.sh sourced from...
# https://github.com/iiab/iiab/blob/master/roles/iiab-admin/templates/sshpwd-profile-iiab.sh

# CAUTION: popup warnings still don't appear on most OS's, as mentioned here:
# https://github.com/iiab/iiab/blob/master/roles/iiab-admin/tasks/pwd-warnings.yml#L19-L25

# For Localization/Translation: (use /usr/bin/gettext below if later nec!)
#export TEXTDOMAIN=pprompt-iiab
#. gettext.sh
# https://github.com/raspberrypi-ui/pam/blob/master/etc/profile.d/sshpwd.sh
# https://github.com/raspberrypi-ui/pprompt/blob/master/sshpwd.sh

# bash syntax "function check_user_pwd() {" was removed, as it prevented all
# lightdm/graphical logins (incl autologin) on Raspbian: #1252 -> PR #1253
check_user_pwd() {
    #id -u $1 > /dev/null 2>&1 || return 2    # Not needed if return 1 is good
    # enough when user does not exist.  Or uncomment to FORCE ERROR CODE 2.
    # Either way, overall bash script still returns exit code 0 ("success")

    # sudo works below (unlike in sshpwd-profile-iiab.sh) b/c RaspiOS ships w/
    # /etc/sudoers.d/010_pi-nopasswd containing "pi ALL=(ALL) NOPASSWD: ALL"
    # (read access to /etc/shadow is otherwise restricted to just root and
    # group www-data i.e. Apache, NGINX get special access).  SEE: #2431, #2561

    # 2021-08-28: New OS's use 'yescrypt' so use Perl instead of Python (#2949)
    # This also helps avoid parsing the (NEW) 4th sub-field in $y$j9T$SALT$HASH
    field2=$(grep "^$1:" /etc/shadow | cut -d: -f2)
    [[ $(perl -e "print crypt('$2', '$field2')") == $field2 ]]

    # # $meth (hashing method) is typically '6' which implies 5000 rounds
    # # of SHA-512 per /etc/login.defs -> /etc/pam.d/common-password
    # meth=$(sudo grep "^$1:" /etc/shadow | cut -d: -f2 | cut -d$ -f2)
    # salt=$(sudo grep "^$1:" /etc/shadow | cut -d: -f2 | cut -d$ -f3)
    # hash=$(sudo grep "^$1:" /etc/shadow | cut -d: -f2 | cut -d$ -f4)
    # [ $(python3 -c "import crypt; print(crypt.crypt('$2', '\$$meth\$$salt'))") == "\$$meth\$$salt\$$hash" ]
}

#grep -q "^PasswordAuthentication\s\+no\b" /etc/ssh/sshd_config && return
#systemctl is-active {{ sshd_service }} || return

if check_user_pwd "{{ iiab_admin_user }}" "{{ iiab_admin_published_pwd }}" ; then    # iiab-admin g0adm1n
    zenity --warning --width=600 --text="Published password in use by user '{{ iiab_admin_user }}'.\n\nTHIS IS A SECURITY RISK - please change its password using IIAB's Admin Console (http://box.lan/admin) -> Utilities -> Change Password.\n\nSee 'What are the default passwords?' at http://FAQ.IIAB.IO"
    #zenity --warning --width=600 --text="SSH is enabled and the published password is in use by user '{{ iiab_admin_user }}'.\n\nTHIS IS A SECURITY RISK - please change its password using IIAB's Admin Console (http://box.lan/admin) -> Utilities -> Change Password.\n\nSee 'What are the default passwords?' at http://FAQ.IIAB.IO"
fi
