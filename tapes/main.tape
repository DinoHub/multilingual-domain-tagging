task GetTaggingLMData
    < tagginglm_dir=@
    > in_domain_preprocessed
    > multi_domain_preprocessed
    > train_preprocessed
    > dev_preprocessed
    > test_preprocessed
    :: in_domain_name=@
    :: multi_domain_name=@
    :: repo=@

 {
    #will return preprocessed version of the data provided
    python $repo/scripts/preprocess.py  $tagginglm_dir/${in_domain_name} > $in_domain_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/${multi_domain_name} > $multi_domain_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/train > $train_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/dev > $dev_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/test > $test_preprocessed

 }

func BuildKenLM
    < kenlm_dir
    < kenlm_train_data
    < test_input
    < repo
    > model
    :: ngram


{
   $kenlm_dir/bin/lmplz -o $ngram < $kenlm_train_data > $kenlm_train_data.arpa
   $kenlm_dir/bin/build_binary $kenlm_train_data.arpa  $model

 }


task BuildKenLMInDomain calls BuildKenLM
    < kenlm_dir=@
    < kenlm_train_data=$in_domain_preprocessed@GetTaggingLMData
    < repo=@
    > model
    :: ngram=@

task BuildKenLMMultiDomain calls BuildKenLM
    < kenlm_dir=@
    < kenlm_train_data=$multi_domain_preprocessed@GetTaggingLMData
    < repo=@
    > model
    :: ngram=@

function KenLMScore
    < kenlm_model
    < input
    < repo
    > kenlm_scores
    > quantiles
    :: is_kenlm_train
    {
    python $repo/scripts/kenlm_score.py $kenlm_model $input > kenlm_scores

    #create quantiles
    if [ "$is_kenlm_train" = "true" ]; then
        python $repo/scripts/quartiles.py --scores_file scores --n_quantiles 4 --action get_quantiles --quantiles_file quantiles > $quantiles
    #assign quantiles
    else
        python $repo/scripts/quartiles.py --scores_file scores --n_quantiles 4 --action assign_quantiles --quantiles_file quantiles > $quantiles
    fi

    }

task ScoreTrainKenlm calls  KenLMScore
    < kenlm_model
    < input
    < repo
    > kenlm_scores








