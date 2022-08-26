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
    :: multidomain_size=@

 {

    python $repo/scripts/select_data.py   $tagginglm_dir/${multi_domain_name} $multidomain_size
    #will return preprocessed version of the data provided
    python $repo/scripts/preprocess.py  $tagginglm_dir/${in_domain_name} > $in_domain_preprocessed
    python $repo/scripts/preprocess.py  $tagginglm_dir/${multi_domain_name}.selected > $multi_domain_preprocessed
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
    < tagginglm_dir
    < in_quantiles
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
        --n_quantiles 4 --action get_quantiles > $quantiles
        quantiles_file=$quantiles

    else
        quantiles_file=$in_quantiles
        cat $in_quantiles > $quantiles
    fi

    #assign quantiles
    python $repo/scripts/quantiles.py --scores_indomain $indomain_kenlm_scores  --scores_multidomain $multidomain_kenlm_scores \
     --n_quantiles 4 --action assign_quantiles --quantiles_file  $quantiles_file  --source_file $tagginglm_dir/$source_file  --tagged_file $tagged_file > tags
    }

task CalculateQuantiles calls  KenLMScore
    < kenlm_model_indomain=$model@BuildKenLMInDomain
    < kenlm_model_multidomain=$model@BuildKenLMMultiDomain
    < input=$tagginglm_test_preprocessed@GetTaggingLMData
    < repo=@
    < tagginglm_dir=@
    < in_quantiles=@
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    :: is_kenlm_train=true
    :: source_file=tagginglm_test
    :: tagged_file=tagginglm_test_tagged


task AssignQuantilesTest calls  KenLMScore
    < kenlm_model_indomain=$model@BuildKenLMInDomain
    < kenlm_model_multidomain=$model@BuildKenLMMultiDomain
    < input=$test_preprocessed@GetTaggingLMData
    < repo=@
    < tagginglm_dir=@
    < in_quantiles=$quantiles@CalculateQuantiles
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    :: is_kenlm_train=false
    :: source_file=test
    :: tagged_file=test_tagged


task AssignQuantilesDev calls  KenLMScore
    < kenlm_model_indomain=$model@BuildKenLMInDomain
    < kenlm_model_multidomain=$model@BuildKenLMMultiDomain
    < input=$dev_preprocessed@GetTaggingLMData
    < repo=@
    < tagginglm_dir=@
    < in_quantiles=$quantiles@CalculateQuantiles
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    :: is_kenlm_train=false
    :: source_file=dev
    :: tagged_file=dev_tagged


task AssignQuantilesTrain calls  KenLMScore
    < kenlm_model_indomain=$model@BuildKenLMInDomain
    < kenlm_model_multidomain=$model@BuildKenLMMultiDomain
    < input=$train_preprocessed@GetTaggingLMData
    < repo=@
    < tagginglm_dir=@
    < in_quantiles=$quantiles@CalculateQuantiles
    > indomain_kenlm_scores
    > multidomain_kenlm_scores
    > quantiles
    :: is_kenlm_train=false
    :: source_file=train
    :: tagged_file=train_tagged




