 # clog> check
# short> pre-build & deploy checks
# extra> $1 == "ignore" to ignore warnings
#                             _                               _      _
#   ___   _ __   ___   _ _   | |_   ___  __ _   ___   _ __   | |_   | |
#  / _ \ | '_ \ / -_) | ' \  |  _| (_-< / _` | |___| | '  \  | ' \  | |
#  \___/ | .__/ \___| |_||_|  \__| /__/ \__, |       |_|_|_| |_||_| |_|
#        |_|                            |___/
[ -f clogrc/common.sh ] && source clogrc/common.sh  # helper functions

# --- status ------------------------------------------------------------------
OOPS=0                                   # non zero is bad - count the problems

# --- check functions ---------------------------------------------------------

# getRemoteTag "opentsg-component" "ref" # get tag. [ -z "$2" ] adds color
function getRemoteTag () {
  local URL="https://github.com/mrmxf/$1.git"
  local TAG=$(git ls-remote --tags $URL v\* 2>/dev/null | head -1 | sed -r 's/.*(v[\.0-9]*).*/\1/')
  [ $? -ne 0 ]  && ((OOPS++)) && return $OOPS         # unknown error on stdout
  if [ -z "$2" ] ; then
    # make all the non-matching tags red
    [[ "$TAG" == "" ]]       && TAG="no tag"
    [[ "$TAG" != "$vREF" ]] && TAG="$cE$TAG"  &&   ((OOPS++))
  fi
  printf $TAG
  return $OOPS
}

# --- git issues handling -----------------------------------------------------
issue=$(git status | grep 'not stage')
[ -n "$issue" ] && printf "${cE}Stage$cT or$cW Stash$cT changes before build$cX\n" && ((OOPS++))

issue=$(git status | grep 'hanges to be comm')
[ -n "$issue" ]  && printf "${cE}Commit$cT changes before build$cX\n" && ((OOPS++))

issue=$(git status | grep 'branch is ahead')
[ -n "$issue" ]  && printf "${cE}Push$cT changes before build$cX\n" && ((OOPS++))

issue=$(git status | grep 'working tree clean')
[ -z "$issue" ] && printf "${cE}Changes!$cT Working Tree must be$cS clean$cT before build$cX\n" && ((OOPS++))

# --- tag handling ------------------------------------------------------------
vCODE=$(awk 'match($0, /"([^"]*)/) { print substr($0, RSTART+1, RLENGTH-1) }' ./versionstr/releases.yml | head -1)
vREF="$vCODE"
vLOCAL=$(git tag | tail -1)       && [ -z "$vLOCAL" ] && vLOCAL="$untagged"
vHEAD=$(git tag --points-at HEAD) && [ -z "$vHEAD" ]  && vHEAD="${cW}untagged"
[[ "$vLOCAL" != "$vREF" ]] && vLOCAL="${cE}$vLOCAL"
[ $OOPS -gt 0 ] && vLOCAL="$cW$vLOCAL"  # use color to warn that tag is dirty


vRcore=$(   getRemoteTag opentsg-core )   ; OOPS=$?
vRio=$(     getRemoteTag opentsg-io )     ; OOPS=$?
vRlab=$(    getRemoteTag opentsg-lab )    ; OOPS=$?
vRmhl=$(    getRemoteTag opentsg-mhl )    ; OOPS=$?
vRnode=$(   getRemoteTag opentsg-node )   ; OOPS=$?
vRwidgets=$( getRemoteTag opentsg-widgets ) ; OOPS=$?

#print out the matching tags
printf "golang code   $cS $vCODE $cX\n"
printf "local  git latest     $cS $vLOCAL$cX\n"
printf "local  git HEAD       $cS $vHEAD$cX\n"
printf "remote opentsg-core   $cS $vRcore    $cX\n"
printf "remote opentsg-io     $cS $vRio      $cX\n"
printf "remote opentsg-lab    $cS $vRlab     $cX\n"
printf "remote opentsg-mhl    $cS $vRmhl     $cX\n"
printf "remote opentsg-node   $cS $vRnode    $cX\n"
printf "remote opentsg-widgets$cS $vRwidgets $cX\n"

# --- environemnt variables ---------------------------------------------------

[ -z "$PROJECT " ] && printf "${cT}env$cE PROJECTI$cT not set.\n" && ((OOPS++))

# --- exit handling -----------------------------------------------------------
if [[ "ignore" == "$1" ]] ; then
  [ $OOPS -gt 0 ] && printf "${cT}Ignoring $cW$OOPS$cT issues from$cC check$cX.\n"
else
  if [ $OOPS -gt 0 ] ; then
    git status --branch --short
    printf "${cE}Error $cW$OOPS$cT issues from$cC check$cX.\n"
    exit $OOPS
  fi
fi