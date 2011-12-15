#!/usr/bin/env bash
#
# !!! CAUTION !!!
# USE THIS SCRIPT AT YOUR OWN RISK, I CAN'T BE RESPONSIBLE FOR HOW AND WHERE YOU USE IT
#
# USAGE: 
# -This script, used with cron, should add all untracked files and check-in them to subversion (files marked with "!")
# -Replace all paths and variables as needed (including <> symbols)
# -Make sure you run this script as an user that has cached SSL certificate (in case your SVN server uses https)
# -The script is compatible with svn client 1.4  
# -Comment "iptables" related lines if you don't need to "stop -> commit -> start" firewall
#
# To DEBUGG uncomment this two lines:
#exec &>/tmp/cron-svn-commit.log
#set -x
 


# make sure LANG is US UTF8
export LANG=en_US.UTF-8

# home folder of the user (it's used to read SSL info from ~/.subversion/auth/svn.ssl.server)
export HOME=/home/<username>

# add/remove e-mail recipient separated by comma
mail_to="<your@e-mail.addr>"

# subversion username
svn_user="<svn_username>"

# subversion password
svn_pass="<svn_password>"

# svn local sources
resources_dir="/path/to/your/repository"

# file with all names of the file that needs to be added or updated
svnlog_add="/tmp/svnlog-add"

# file with all names of the files that needs to be deleted
svnlog_delete="/tmp/svnlog-delete"

# command to start iptables program
start_iptables="service iptables start"

# command to stop iptables program
stop_iptables="service iptables stop"

# subversion commit command & message log
svn_commit_msg="<few words for svn log> `date +%c`"



# function to add files on subversion
function add_files_to_svn() {
  ( cd $resources_dir && svn status | grep -e "^[M\?]" | awk -F"       " '{ print ""$2"" }' | sed -r "s/ /\\\ /g" | xargs svn add ) 
}

# function to delete files from subversion
function delete_files_from_svn() {
  ( cd $resources_dir && svn status | grep -e "^\!" | awk -F"       " '{ print ""$2"" }' | sed -r "s/ /\\\ /g" | xargs svn delete )
}

# function to commit new files
function commit_files_on_svn() {
  ( svn commit $resources_dir --username $svn_user --password $svn_pass --non-interactive -m "$svn_commit_msg" )
}

# create needed log files
( cd $resources_dir && svn status | grep -e "^[M\?]" > $svnlog_add )
( cd $resources_dir && svn status | grep -e "^\!" > $svnlog_delete )



# final commit procedure
if [[ -s "$svnlog_add" ]] || [[ -s "$svnlog_delete" ]]; then
  cat $svnlog_add | mail -s "svnlog | `hostname` | `date +%F-%T`" $mail_to
  add_files_to_svn
  delete_files_from_svn
  $stop_iptables 
  commit_files_on_svn
  $start_iptables 
fi



exit $?
