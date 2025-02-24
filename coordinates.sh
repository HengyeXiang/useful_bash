#!/bin/bash

# remove SI_coordinates.txt if file already exists.
rm -f SI_coordinates.txt

list_file="list.txt"

file_names=()

if [ -e "$list_file" ]; then
    while IFS= read -r name || [ -n "$name" ]; do
        file_names+=(''${name}'.out')   
    done < "$list_file"
else
    for file in `ls -1 *.out | grep -v '\_sp.out'`
    do
    	file_names+=("$file")	       
    done
fi

for file in "${file_names[@]}";
do
        name=`basename ${file} .out`
	E_opt=`grep 'SCF Done:  E(' ${file} | tail -1 | awk '{print $5}'`
  	H_corr=`grep 'Thermal correction to Enthalpy' ${file} | awk '{print $5}'`
  	G_corr=`grep 'Thermal correction to Gibbs Free Energy' ${file} | awk '{print $7}'`
  	E_sp=`grep 'SCF Done:  E(' ${name}_sp.out | tail -1 | awk '{print $5}'`
        # For ORCA SPE, use : E_sp=`grep 'FINAL SINGLE POINT ENERGY' ${name}_SP.out | tail -1 | awk '{print $5}'`
  	H_opt=$(echo "${E_opt} + ${H_corr}" | bc)
  	G_opt=$(echo "${E_opt} + ${G_corr}" | bc)
  	H_sp=$(echo "${E_sp} + ${H_corr}" | bc)
  	G_sp=$(echo "${E_sp} + ${G_corr}" | bc)
	    
	freq1=`grep -m 1 'Frequencies --' ${file} | awk '{print $3}'`
  	freq2=`grep -m 1 'Frequencies --' ${file} | awk '{print $4}'`

	if (( $(echo "$freq1 < 0 && $freq2 > 0" | bc -l)  || $(echo "$freq1 > 0 && $freq2 > 0" | bc -l) )); then
	    python3.6 -m goodvibes --qs truhlar -f 100 -v 1 -c 1 ${name}.out --xyz > Goodvibes_output.log
	    # if you encounter any error message regarding to python, change the "python" above to "python3.6"
  	    sed -i -n '/Structure/,$p' Goodvibes_output.log
  	    sed -i -e '1,2d' Goodvibes_output.log
  	    G_opt_qh=`sed '$d' Goodvibes_output.log | awk '{print $9}'`
  	    G_sp_qh=$(echo "${G_opt_qh} - ${E_opt} + ${E_sp}" | bc)
  	    sed -i -e '1,2d' Goodvibes_output.xyz
  
  	    echo ${name} 						                >> SI_coordinates.txt
  	    echo 'B3LYP-D3 SCF energy (au):                  '${E_opt}'' 	        >> SI_coordinates.txt
  	    echo 'B3LYP-D3 enthalpy (au):                    '${H_opt}'' 	        >> SI_coordinates.txt
  	    echo 'B3LYP-D3 free energy (au):                 '${G_opt_qh}'' 	>> SI_coordinates.txt
  	    echo 'M062X/PBE SCF energy in solution (au):           '${E_sp}'' 	        >> SI_coordinates.txt
  	    echo 'M062X/PBE enthalpy in solution (au):             '${H_sp}'' 	        >> SI_coordinates.txt
  	    #echo 'M06 free energy (not quasi harmonic) in solution (au):          '${G_sp}'' 	>> SI_coordinates.txt
  	    echo 'M062X/PBE free energy in solution (au):          '${G_sp_qh}'' 	>> SI_coordinates.txt
	    if(( $(echo "$freq1 < 0 && $freq2 > 0" | bc -l) )); then
		rounded_freq1=$(echo "scale=1; $freq1/1" | bc)
     	    	echo 'Imaginary frequency:                       '${rounded_freq1}'cm-1'   >> SI_coordinates.txt
	    fi
  	    echo ''				 		>> SI_coordinates.txt
  	    echo 'Cartesian coordinates'		 		>> SI_coordinates.txt
  	    echo 'ATOM	X             Y           Z' 		>> SI_coordinates.txt
	    if [ "$1" = "-i" ]; then
		temp_file=$(mktemp)
		awk '{printf("%s    %9.6f    %9.6f    %9.6f\n", $1, $2*-1, $3*-1, $4*-1)}' Goodvibes_output.xyz > "$temp_file"
		mv "$temp_file" Goodvibes_output.xyz
	    fi
  	    cat Goodvibes_output.xyz				>> SI_coordinates.txt
  	    echo ''					 	>> SI_coordinates.txt

	elif (( $(echo "$freq1 < 0 && $freq2 < 0" | bc -l) )); then
	    echo ''${name}'.out has two imaginary frequencies, please double check the file!'  >> SI_coordinates.txt
	    echo ''					 	>> SI_coordinates.txt
	fi
	
	echo 'Process for '${name}' has finished.'
done

rm -f Goodvibes_output.*
