#Instruct terminal colors as Unix style
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export AMOS_HOME=~/Workspace/AmosNT
export CVS_RSH=ssh
export CVS_SERVER=cvs
export CVSROOT=:ext:$CVS_USERID@hamberg.it.uu.se:/dis/projects/udbl/CVSRoot
#export JAVA_HOME=~/Workspace/jdk1.6.0_20/
#export CLASSPATH=$JAVA_HOME/lib/
#export PATH=$JAVA_HOME/bin/:$AMOS_HOME/bin/:$PATH
export PATH=$AMOS_HOME/bin/:$PATH 
export MYSQL_HOME=~/Workspace/mysql-5.1.34-linux-i686-glibc23/
export JENA_HOME=~/Workspace/Jena-2.1
export TMPDIR=~/Workspace/scratch
export ARCHITECTURE=Apple32
export EDITOR=Emacs
alias Emacs="/Applications/Emacs.app/Contents/MacOS/Emacs"
export JAVA_HOME=/Library/Java/Home/
export CLASSPATH=$JAVA_HOME/lib
alias gmake="make"
alias startMysql="/Applications/MAMP/bin/startMysql.sh"
alias stopMysql="/Applications/MAMP/bin/stopMysql.sh"
alias mysql="/Applications/MAMP/Library/bin/mysql --host=localhost -uroot -proot"
function tabname {
  printf "\e]1;$1\a"
}
 
function winname {
  printf "\e]2;$1\a"
}

comm_tw() {
        [ $# -lt 2 ] && return
        osascript -e "
                tell application \"System Events\" to tell process \"Terminal\" to keystroke \"$1\" using command down
                tell application \"Terminal\" to do script \"$2\" in selected tab of the front window
        " > /dev/null 2>&1
}
newt() {
    comm_tw t "$1"
}
neww() {
    comm_tw n "$1"
}