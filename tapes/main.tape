task GetTaggingLMData
    < tagginglm_dir=@
    > in_domain_preprocessed
    > multi_domain_preprocessed
    > tagginglm_test_preprocessed
    > train_preprocessed
    > dev_preprocessed
    > test_preprocessed
    :: in_domain_name=@
    :: multi_domain_name=@
    :: tagging_test_name=@
    :: repo=@

 {
    #will return preprocessed version of the data provided
    python $repo/scripts/preprocess.py  $tagginglm_dir/${in_domain_name} > $in_domain_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/${multi_domain_name} > $multi_domain_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/${tagging_test_name} > $tagginglm_test_preprocessed
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

func KenLMScore
    < kenlm_model_indomain
    < kenlm_model_multidomain
    < input
    < repo
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    :: is_kenlm_train
    :: source_file
    :: tagged_file
    {
    python $repo/scripts/kenlm_score.py $kenlm_model_indomain $input > $indomain_kenlm_scores
    python $repo/scripts/kenlm_score.py $kenlm_model_multidomain $input > $multidomain_kenlm_scores

    #create quantiles
    if [ "$is_kenlm_train" = "true" ]; then
        python $repo/scripts/quantiles.py --scores_indomain $indomain_kenlm_scores  --scores_multidomain $multidomain_kenlm_scores \
        --n_quantiles 4 --action get_quantiles --quantiles_file $quantiles
    #assign quantiles
    else
        python $repo/scripts/quantiles.py --scores_file $kenlm_scores --n_quantiles 4 --action assign_quantiles \
         --quantiles_file $quantiles  --source_file $source_file   --tagged_file $tagged_file > tags
    fi

    }

task ScoreTrainKenlm calls  KenLMScore
    < kenlm_model_indomain=$model@BuildKenLMInDomain
    < kenlm_model_multidomain=$model@BuildKenLMMultiDomain
    < input=$tagginglm_test_preprocessed@GetTaggingLMData
    < repo=@
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    :: is_kenlm_train=true
    :: source_file=None
    :: tagged_file=None








