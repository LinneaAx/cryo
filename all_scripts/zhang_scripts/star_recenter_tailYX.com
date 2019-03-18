#!/bin/tcsh -f

#recenter Phi-particles using the center of tail

# 


set allstarf="run9_it050_particles_class???_good1.star"
#run4_P2_it050_particles_shrink2_good1_class00??.star"
set suffix=center2
set centefile="tail_center.txt"   #this file containing the centers of each class average, two columns e.g. 120 178

set boxsize=360


####### end of user input ######################

set i=1

foreach starf ( $allstarf )

set dxy=`gawk 'NR=='$i'' $centefile`
set dx=`echo $dxy|gawk '//{print $1 - '$boxsize'/2}'`   
set dy=`echo $dxy|gawk '//{print $2 - '$boxsize'/2}'`  



echo "$starf  $dx  $dy"

########################
set root_name=`basename $starf  .star`
set newstarf=${root_name}_tmp.star
set out_root=${root_name}_${suffix}
set outstarf=${out_root}.star

set rlnOriginXIndex=`gawk 'NR<50 && /_rlnOriginX/{print $2}' $starf  |cut -c 2- `
set rlnOriginYIndex=`gawk 'NR<50 && /_rlnOriginY/{print $2}' $starf |cut -c 2- `
set rlnAnglePsiIndex=`gawk 'NR<50 && /_rlnAnglePsi/{print $2}' $starf |cut -c 2- `
set rlnImageNameIndex=`gawk 'NR<50 && /_rlnImageName/{print $2}' $starf |cut -c 2- `

set headN=`gawk '{if($2 ~ /#/)N=NR;}END{print N}' $starf `
gawk 'NR <= '$headN'' $starf > $newstarf
gawk 'NR <= '$headN'' $starf > $outstarf

set columnN=`gawk 'NR<50 && /_rln/{a=$2;}END{print a;}' $starf |cut -c 2- `
########################

gawk '/mrcs/{ PI=atan2(0, -1 ); \
x =  -cos($'$rlnAnglePsiIndex' * PI /180) * '$dx' - sin($'$rlnAnglePsiIndex' * PI /180) * '$dy' + $'$rlnOriginXIndex'; \
y =   sin($'$rlnAnglePsiIndex' * PI /180) * '$dx' - cos($'$rlnAnglePsiIndex' * PI /180) * '$dy' + $'$rlnOriginYIndex'; \
for(i=1;i<='$columnN';i++){\
  if     (i == '$rlnOriginXIndex' ) printf("%d ", x);\
  else if(i == '$rlnOriginYIndex' ) printf("%d ", y);\
  else if(i == '$rlnAnglePsiIndex') printf("%d ", 0);\
  else printf("%s ", $i);\
}\
printf("\n");\
}'  $starf >> $newstarf

gawk '/mrcs/{fN++; PI=atan2(0, -1 ); \
x =  -cos($'$rlnAnglePsiIndex' * PI /180) * '$dx' - sin($'$rlnAnglePsiIndex' * PI /180) * '$dy' + $'$rlnOriginXIndex'; \
y =   sin($'$rlnAnglePsiIndex' * PI /180) * '$dx' - cos($'$rlnAnglePsiIndex' * PI /180) * '$dy' + $'$rlnOriginYIndex'; \
for(i=1;i<='$columnN';i++){\
  if     (i == '$rlnOriginXIndex' ) printf("%d ", 0);\
  else if(i == '$rlnOriginYIndex' ) printf("%d ", 0);\
  else if(i == '$rlnAnglePsiIndex') printf("%d ", 0);\
  else if(i == '$rlnImageNameIndex') printf("%d@%s.mrcs  ", fN, "'$out_root'");\
  else printf("%s ", $i);\
}\
printf("\n");\
}'  $starf >> $outstarf

relion_stack_create --i $newstarf  --o ${out_root} --apply_transformation

#cat $newstarf
rm -f star_head$$.star

@ i++
end #end foreach
