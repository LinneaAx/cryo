#!/bin/tcsh -f



set all_mrcfs	=	`ls Micrographs/Falcon*SumCorr.mrc`
set all_hosts	=	( hal hex lg18 lg19 lg20  lg21 lg22 hal hex lg18 lg19 lg20  lg21 lg22 hal hex )
set Gctf_cmd	=	"Gctf --apix 1.34"

set i = 1
set mrcfN=${#all_mrcfs}



########################################################################
######################### Checking  ####################################
########################################################################
set hosts_tmp = ""
set id = 0
foreach host ($all_hosts)

set stat = `ssh $host "gpu_info |grep Success "`

set status = "$stat"
if (  "$status" == "" ) then

echo "$host Failed, automatically skipping it ..."

else

set hosts_tmp = "$hosts_tmp "$host 
@ id++
set regID = `echo $id |gawk '{printf("%02d",$1);}'`
echo "cd `pwd`" >  Gctf_command${regID}_${host}.csh
printf "$Gctf_cmd  --ctfstar micrographs${regID}_${host}_gctf.star  "  >>  Gctf_command${regID}_${host}.csh 

endif

end


set all_hosts	=	( $hosts_tmp )

echo "All Available hosts: $all_hosts"

########################################################################
###################### Checking finishes ###############################
########################################################################


while ( $i <= $mrcfN )
#while 100

set id = 0

foreach host ($all_hosts)

#echo "$host ................."
#printf "cd `pwd`\n" 

if ( $i <= $mrcfN  ) then
@ id++

set regID = `echo $id |gawk '{printf("%02d",$1);}'`

printf "  $all_mrcfs[$i]" >>  Gctf_command${regID}_${host}.csh
printf .
endif

@ i++
end

end #end while 100

printf "\n" 


########################################################################
########################################################################
########################################################################

set id = 0

foreach host ($all_hosts)

@ id++
set regID = `echo $id |gawk '{printf("%02d",$1);}'`

printf " > Gctf_all_log${regID}_${host}.txt\n echo done > .GCTF_DONE${regID}_${host}" >> Gctf_command${regID}_${host}.csh

chmod +x Gctf_command${regID}_${host}.csh
rm -f .GCTF_DONE${regID}_${host} 
ssh ${host}  `pwd`/Gctf_command${regID}_${host}.csh &
end

########################################################################
########################################################################
########################################################################

while ( 1 )

set all_done = 1

set id = 0

foreach host ($all_hosts)
@ id++
set regID = `echo $id |gawk '{printf("%02d",$1);}'`


if ( ! -f .GCTF_DONE${regID}_${host}  ) then
set all_done = 0
endif
end

if ( $all_done == 1 ) then

set id = 0

head -n 16 micrographs01_${all_hosts[1]}_gctf.star > micrographs_all_merged_gctf.star

foreach host ($all_hosts)
@ id++

set regID = `echo $id |gawk '{printf("%02d",$1);}'`

gawk '/mrc/'  micrographs${regID}_${host}_gctf.star  >> micrographs_all_merged_gctf.star
rm -f .GCTF_DONE${regID}_${host}  micrographs${regID}_${host}_gctf.star 

end

exit

endif

sleep 3s

end

########################################################################
########################################################################
########################################################################

exit
@ host_index = $host_index + 1
set host_cur=${hosts[$host_index]}
@ next_index = $next_index + ${cores[$host_index]}

echo "cd `pwd`" >  .temp_${host_cur}_command_${cur_cycle}_${startn}_${endn}.csh
echo "./frealign_ref_part.com   ${startn}  ${endn}  $cur_cycle " >> .temp_${host_cur}_command_${cur_cycle}_${startn}_${endn}.csh
chmod +x .temp_${host_cur}_command_${cur_cycle}_${startn}_${endn}.csh
echo
ssh ${host_cur}  `pwd`/.temp_${host_cur}_command_${cur_cycle}_${startn}_${endn}.csh &
