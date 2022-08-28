task GetData
    < data_dir=@
    > tagginglm_dir
    > untagged_train
    > untagged_test
    > untagged_valid
    :: tagging_lang=@ src_lang=@ tgt_lang=@

 {
    if [ $tagging_lang = $src_lang ]; then
       untagged_lang=$tgt_lang
    elif [ $tagging_lang = $tgt_lang ]; then
       untagged_lang=$src_lang
    else
        echo "check your languages"
        exit 1
    fi

    # Build a tagggingLM dir and put all the data there
    mkdir -p $tagginglm_dir

    for file in $data_dir/*.$tagging_lang; do
    [ -f "$file" ] || break
     cp $file $tagginglm_dir/
    done

    ln -s $data_dir/train.${untagged_lang} $untagged_train
    ln -s $data_dir/test.${untagged_lang} $untagged_test
    ln -s $data_dir/valid.${untagged_lang} $untagged_valid





 }

task PreprocessTaggingLMData
    < tagginglm_dir=$tagginglm_dir@GetData
    > in_domain_preprocessed
    > multi_domain_preprocessed
    > tagginglm_test_preprocessed
    > train_preprocessed
    > valid_preprocessed
    > test_preprocessed
    :: in_domain_name=@
    :: multi_domain_name=@
    :: tagging_test_name=@
    :: tagging_lang=@
    :: repo=@
 {

    python $repo/scripts/preprocess.py  $tagginglm_dir/${in_domain_name}.${tagging_lang} > $in_domain_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/${multi_domain_name}.${tagging_lang}> $multi_domain_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/${tagging_test_name}.${tagging_lang} > $tagginglm_test_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/train.${tagging_lang} > $train_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/valid.${tagging_lang} > $valid_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/test.${tagging_lang} > $test_preprocessed

 }

func BuildKenLM
    < kenlm_dir
    < kenlm_train_data
    < repo
    > model
    :: ngram
    :: train_size

{
    file_size=`wc -l $kenlm_train_data`
    size=$(echo $file_size | cut -d " " -f 1)

   if  [ $train_size != size]; then
      python $repo/scripts/select_data.py   $kenlm_train_data $train_size      #will return preprocessed version of the data provided
      $kenlm_dir/bin/lmplz -o $ngram < $kenlm_train_data.selected > $kenlm_train_data.arpa

   else
      $kenlm_dir/bin/lmplz -o $ngram < $kenlm_train_data > $kenlm_train_data.arpa

   fi
   $kenlm_dir/bin/build_binary $kenlm_train_data.arpa  $model

 }


task BuildKenLMInDomain calls BuildKenLM
    < kenlm_dir=@
    < kenlm_train_data=$in_domain_preprocessed@PreprocessTaggingLMData
    < repo=@
    > model
    :: ngram=@ train_size=$indomain_size


task BuildKenLMMultiDomain calls BuildKenLM
    < kenlm_dir=@
    < kenlm_train_data=$multi_domain_preprocessed@PreprocessTaggingLMData
    < repo=@
    > model
    :: ngram=@ train_size=$multidomain_size


func KenLMScore
    < kenlm_model_indomain
    < kenlm_model_multidomain
    < input
    < repo
    < tagginglm_dir
    < in_quantiles
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    > tagged_file
    :: is_calc_quants
    :: source_file
    :: tagging_lang
    {
    python $repo/scripts/kenlm_score.py $kenlm_model_indomain $input > $indomain_kenlm_scores
    python $repo/scripts/kenlm_score.py $kenlm_model_multidomain $input > $multidomain_kenlm_scores

    #create quantiles
    if [ "$is_calc_quants" = "true" ]; then
        python $repo/scripts/quantiles.py --scores_indomain $indomain_kenlm_scores  --scores_multidomain $multidomain_kenlm_scores \
        --n_quantiles 4 --action get_quantiles > $quantiles
        quantiles_file=$quantiles

    else
        quantiles_file=$in_quantiles
        cat $in_quantiles > $quantiles
    fi

    #assign quantiles
    python $repo/scripts/quantiles.py --scores_indomain $indomain_kenlm_scores  --scores_multidomain $multidomain_kenlm_scores \
     --n_quantiles 4 --action assign_quantiles --quantiles_file  $quantiles_file  --source_file $tagginglm_dir/$source_file.$tagging_lang  --tagged_file $tagged_file > tags
    }

task CalculateQuantiles calls  KenLMScore
    < kenlm_model_indomain=$model@BuildKenLMInDomain
    < kenlm_model_multidomain=$model@BuildKenLMMultiDomain
    < input=$tagginglm_test_preprocessed@PreprocessTaggingLMData
    < repo=@
    < tagginglm_dir=$tagginglm_dir@GetData
    < in_quantiles=@
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    > tagged_file=tagginglm_test_tagged
    :: is_calc_quants=true source_file=tagginglm_test tagging_lang=@


task AssignQuantilesTest calls  KenLMScore
    < kenlm_model_indomain=$model@BuildKenLMInDomain
    < kenlm_model_multidomain=$model@BuildKenLMMultiDomain
    < input=$test_preprocessed@PreprocessTaggingLMData
    < repo=@
    < tagginglm_dir=$tagginglm_dir@GetData
    < in_quantiles=$quantiles@CalculateQuantiles
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    > tagged_file=test_tagged
    :: is_calc_quants=false source_file=test tagging_lang=@



task AssignQuantilesValid calls  KenLMScore
    < kenlm_model_indomain=$model@BuildKenLMInDomain
    < kenlm_model_multidomain=$model@BuildKenLMMultiDomain
    < input=$valid_preprocessed@PreprocessTaggingLMData
    < repo=@
    < tagginglm_dir=$tagginglm_dir@GetData
    < in_quantiles=$quantiles@CalculateQuantiles
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    > tagged_file=valid_tagged
    :: is_calc_quants=false source_file=valid tagging_lang=@



task AssignQuantilesTrain calls  KenLMScore
    < kenlm_model_indomain=$model@BuildKenLMInDomain
    < kenlm_model_multidomain=$model@BuildKenLMMultiDomain
    < input=$train_preprocessed@PreprocessTaggingLMData
    < repo=@
    < tagginglm_dir=$tagginglm_dir@GetData
    < in_quantiles=$quantiles@CalculateQuantiles
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    > tagged_file=train_tagged
    :: is_calc_quants=false source_file=train tagging_lang=@


func ApplyBPE
    < raw_untagged
    < raw_tagged
    < spm_model
    > spm_tagged
    > spm_untagged
    :: repo
    :: src_lang
    :: tgt_lang
{

    python $repo/scripts/spm_encode.py --input_file $raw_untagged  --out_file spm_untagged \
    --model_name=$spm_model
    python $repo/scripts/spm_encode.py --input_file $raw_tagged --out_file spm_tagged \
    --model_name=$spm_model

}

task ApplyBPETrain calls ApplyBPE
    < raw_untagged=$untagged_train@GetData
    < raw_tagged=$tagged_file@AssignQuantilesTrain
    < spm_model=@
    > spm_tagged
    > spm_untagged
    :: repo=@ src_lang=@ tgt_lang=@


task ApplyBPEValid calls ApplyBPE
    < raw_untagged=$untagged_valid@GetData
    < raw_tagged=$tagged_file@AssignQuantilesValid
    < spm_model=@
    > spm_tagged
    > spm_untagged
    :: repo=@ src_lang=@ tgt_lang=@


task ApplyBPETest calls ApplyBPE
    < raw_untagged=$untagged_test@GetData
    < raw_tagged=$tagged_file@AssignQuantilesTest
    < spm_model=@
    > spm_tagged
    > spm_untagged
    :: repo=@ src_lang=@ tgt_lang=@










