task GetTaggingLMData
    < tagginglm_dir=@
    > in_domain
    > multi_domain
    :: in_domain_name=@
    :: multi_domain_name=@
    :: repo=@

 {
    #will return preprocessed version of the data provided
    python $repo/scripts/preprocess.py  $tagginglm_dir/${in_domain_name} > $in_domain
    python $repo/scripts/preprocess.py  $tagginglm_dir/${multi_domain_name} > $multi_domain

 }
