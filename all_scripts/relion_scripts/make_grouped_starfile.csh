#!/usr/bin/env csh
#
if ($# == 3) then 
 set split_file = $1
 set input_star = $2
 set output_star = $3
  
 # make the groups.dat file: col1=micrographname, col2= groupname
 cat $split_file | awk 'BEGIN {igroup=1} {if ($NF<1) {igroup++} else {print $1, "group_"igroup} }' > groups.dat   

 # make the header
 awk 'BEGIN {i=1} {if (NF<3) {print $0; if ($1~"_rln") i++; } else {exit} } END {print "_rlnGroupName #"i}' < $input_star > $output_star 

 # How many lines are there in the header?
 set nhead = `wc -l $output_star | awk '{print $1}'`

 # check in which column _rlnMicrographName is stored
 set colno=`grep _rlnMicrographName $input_star | awk -F"#" '{print $2}'`

 # change all lines in the input starfile to have the corresponding groupname added to it
 set ll = 0
 set nl = `wc -l groups.dat | awk '{print $1}'`
 set ntot = 0
 set ngroup = 0
 set oldgroupname=`head -1 groups.dat|awk '{print $2}'`
 while ($ll < $nl)
   @ ll++
   set line=`head -n $ll groups.dat | tail -1` 

   # foreach group print the number of particles in it
   if ($oldgroupname != $line[2] && $ll > 2 ) then
     echo $oldgroupname" has " $ngroup " particles; total number of particles= " $ntot 
     set ngroup = 0;
     set oldgroupname=$line[2]
   endif

   # edit the lines of the output starfile: add groupname at the end of it 
   cat $input_star | awk -v"micname=$line[1]" -v "grname=$line[2]" -v"colno=${colno}" '{if (NF>2) { if ($colno==micname) print $0,grname}  }' >> $output_star 

   # keep track of total number of particles and number of particles in this group
   set ncurr = `wc -l $output_star| awk -v"nhead=$nhead" '{print $1 - nhead}'`
   @ ngroup += $ncurr - $ntot 
   @ ntot = $ncurr 

 end
 echo $oldgroupname" has " $ngroup " particles; total number of particles= " $ntot 
else
 echo "Usage: " $0 " splitfile particles.star particles_grouped.star "
endif
