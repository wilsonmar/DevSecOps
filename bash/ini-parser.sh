#!/usr/bin/env bash
# This is ini-parser.sh in https://github.com/wilsonmar/DevSecOps/.../bash/ini-parser.sh
# STATUS: NOT OPERATIONAL. Initital copy from original source
# based on http://theoldschooldevops.com/2008/02/09/bash-ini-parser/ by Andrés J. Díaz

# This parses a Windows INI formatted .ini file to memory variables.

# USAGE: .ini-parser.sh 'myfile.ini'
# would parse a (Windows INI) config file 'myfile.ini' with the following sample contents:
#   [sec2]
#   var2='something'
 
# enable section called 'sec2' (in the file [sec2]) for reading
# cfg.section.sec2
 
# read the content of the variable called 'var2' (in the file
# var2=XXX). If your var2 is an array, then you can use
# ${var[index]}

# echo "$var2"


cfg_parser ()
{
    ini="$(<$1)"                # read the file
    ini="${ini//[/\[}"          # escape [
    ini="${ini//]/\]}"          # escape ]
    IFS=$'\n' && ini=( ${ini} ) # convert to line-array
    ini=( ${ini[*]//;*/} )      # remove comments with ;
    ini=( ${ini[*]/\    =/=} )  # remove tabs before =
    ini=( ${ini[*]/=\   /=} )   # remove tabs be =
    ini=( ${ini[*]/\ =\ /=} )   # remove anything with a space around =
    ini=( ${ini[*]/#\\[/\}$'\n'cfg.section.} ) # set section prefix
    ini=( ${ini[*]/%\\]/ \(} )    # convert text2function (1)
    ini=( ${ini[*]/=/=\( } )    # convert item to array
    ini=( ${ini[*]/%/ \)} )     # close array parenthesis
    ini=( ${ini[*]/%\\ \)/ \\} ) # the multiline trick
    ini=( ${ini[*]/%\( \)/\(\) \{} ) # convert text2function (2)
    ini=( ${ini[*]/%\} \)/\}} ) # remove extra parenthesis
    ini[0]="" # remove first element
    ini[${#ini[*]} + 1]='}'    # add the last brace
    eval "$(echo "${ini[*]}")" # eval the result
}
 
cfg_writer ()
{
    IFS=' '$'\n'
    fun="$(declare -F)"
    fun="${fun//declare -f/}"
    for f in $fun; do
        [ "${f#cfg.section}" == "${f}" ] && continue
        item="$(declare -f ${f})"
        item="${item##*\{}"
        item="${item%\}}"
        item="${item//=*;/}"
        vars="${item//=*/}"
        eval $f
        echo "[${f#cfg.section.}]"
        for var in $vars; do
            echo $var=\"${!var}\"
        done
    done
}

