#        _
#   __  | |  ___   __ _
#  / _| | | / _ \ / _` |
#  \__| |_| \___/ \__, |
#                 |___/
#
# expecting gitlab env: $GLAT
# expecting docker env
#

export bPROJECT=$(basename $(pwd))              # project you're building
export vCODE=$(clog git vcode)                  # reference code version
export bucket=$(clog get bucket)
export bCodeType="Golang"
export bBase="opentsg-node"
export bMSG="$(clog git message ref)"            # reference message
export bHASH="$(clog git hash head)"              # hash of head commit
# add a suffix to any build not on the main branch
export bSUFFIX="$(git branch --show-current)" && [[ "$bSUFFIX"=="main" ]] && bSUFFIX=""
