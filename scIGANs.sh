#!/bin/bash
## parsing the arguments
epochs=200 # number of epochs for training
sim_size=200 # number of simulated datasets for imputation
knn_k=10 # number of the neighbours used for imputation
label="" # file path for cell labels
process=20
PARAMS=""
#e_matrix=$1 ## the first argument is the input expression matrix

outdir=`pwd`
Bashdir=$(dirname $BASH_SOURCE)
version="0.1.1"
while (( "$#" )); do
  case "$1" in
    -l|--label_file)
      label=$2
      shift 2
      ;;
    -n|--n_epochs)
      epochs=$2
      shift 2
      ;;
    -s|--sim_size)
      sim_size=$2
      shift 2
      ;;
    -k|--knn_k)
      knn_k=$2
      shift 2
      ;;
    -p|--process)
      process=$2
      shift 2
      ;;
    -o|--outdir)
      outdir=$2
      shift 2
      ;;
    -h|--help)
	echo "scIGANs_0.1.1"
    echo "Usage: scIGANs exp_matrix [options]"
	echo "-h | --help		show this message"
	echo "-l | --label_file <string>	optional	give the label of cell type or subpopulation for each cell, with the same order of the colounms in expression matrix."
	echo "-n | --n_epochs <integer>		set the number of epochs of training. Default = 200"
	echo "-s | --sim_size <integer>		set the number of generated data for imputation. Default = 200"
	echo "-k | --knn_k <integer>		set the number of nearest neighbours used for imputation. Default = 10"
	echo "-p | --process <integer>		number of cpu threads. Default = 20"
	echo "-o | --outdir <string>		set the path where to write the imputed matrix. Default: current working directory (pwd)."
    shift
	exit
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported argument $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"
e_matrix=$(awk -v OFS=" "  '{print $1}' <<< $PARAMS)
set -e
# create a tmp folder for intermediate outputs
tmp='tmp'$RANDOM
mkdir -p $tmp
echo "scIGANs_0.1.1"
out=`Rscript ${Bashdir}/src/inpro.R ${e_matrix} $tmp $label`
nf=$(awk -F_ '{print $3}' <<< $out)
ncls=$(awk -F_ '{print $4}' <<< $out)
fname=`basename $e_matrix` ## get the filename without path
for (( i=1; i<=$nf; i++ ))
do
	echo $tmp/${i}_${fname}
	python ${Bashdir}/src/imputeByGans.py --file_d=$tmp/${i}_${fname} --file_c=${e_matrix}.label.csv --ncls=$ncls --n_epochs=$epochs --sim_size=$sim_size --knn_k=$knn_k --n_cpu=$process --train
	python ${Bashdir}/src/imputeByGans.py --file_d=$tmp/${i}_${fname} --file_c=${e_matrix}.label.csv --ncls=$ncls --n_epochs=$epochs --sim_size=$sim_size --knn_k=$knn_k --n_cpu=$process --impute
done

Rscript ${Bashdir}/src/outpro.R $fname $tmp $outdir
rm -r $tmp
