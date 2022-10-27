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
    > tags
    :: is_calc_quants
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
     --n_quantiles 4 --action assign_quantiles --quantiles_file  $quantiles_file   > $tags
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
    > tags
    :: is_calc_quants=true tagging_lang=@


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
    > tags
    :: is_calc_quants=false  tagging_lang=@



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
    > tags
    :: is_calc_quants=false  tagging_lang=@



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
    > tags
    :: is_calc_quants=false  tagging_lang=@


func ApplyBPE
    < raw_untagged
    < tagginglm_dir
    < tags
    < repo
    < spm_model
    > spm_tagged
    > spm_untagged
    :: src_lang
    :: tgt_lang
    :: tagging_lang
    :: raw_totag
{

    python $repo/scripts/spm_encode.py --input_file $raw_untagged  --out_file spm_untagged \
    --model_name=$spm_model
    python $repo/scripts/spm_encode.py --input_file $tagginglm_dir/$raw_totag.$tagging_lang --out_file spm_totag \
    --model_name=$spm_model

    python $repo/scripts/tag.py --file2tag spm_totag --tags $tags --tagged_file $spm_tagged

}

task ApplyBPETrain calls ApplyBPE
    < raw_untagged=$untagged_train@GetData
    < tagginglm_dir=$tagginglm_dir@GetData
    < tags=$tags@AssignQuantilesTrain
    < repo=@
    < spm_model=@
    > spm_tagged
    > spm_untagged
    :: src_lang=@ tgt_lang=@ tagging_lang=@ raw_totag=train


task ApplyBPEValid calls ApplyBPE
    < raw_untagged=$untagged_valid@GetData
    < tagginglm_dir=$tagginglm_dir@GetData
    < tags=$tags@AssignQuantilesValid
    < repo=@
    < spm_model=@
    > spm_tagged
    > spm_untagged
    :: src_lang=@ tgt_lang=@ tagging_lang=@ raw_totag=valid


task ApplyBPETest calls ApplyBPE
    < raw_untagged=$untagged_test@GetData
    < tagginglm_dir=$tagginglm_dir@GetData
    < tags=$tags@AssignQuantilesTest
    < repo=@
    < spm_model=@
    > spm_tagged
    > spm_untagged
    :: src_lang=@ tgt_lang=@ tagging_lang=@ raw_totag=test


task BinarizeData
    < train_tagged=$spm_tagged@ApplyBPETrain
    < train_untagged=$spm_untagged@ApplyBPETrain
    < valid_tagged=$spm_tagged@ApplyBPEValid
    < valid_untagged=$spm_untagged@ApplyBPEValid
    < test_tagged=$spm_tagged@ApplyBPETest
    < test_untagged=$spm_untagged@ApplyBPETest
    < src_dict=@
    < tgt_dict=@
    > bin_dir
    :: .submitter=@ .cpus=8 .mem=32000M
    :: repo=@
    :: src_lang=@
    :: tgt_lang=@
    :: tagging_lang=@
    :: has_train=true
{
     if [ $tagging_lang = $src_lang ]; then
       untagged_lang=$tgt_lang
    elif [ $tagging_lang = $tgt_lang ]; then
       untagged_lang=$src_lang
    else
        echo "check your languages"
        exit 1
    fi

    # symlink for fairseq format
    ln -s $train_tagged train.${tagging_lang}
    ln -s $train_untagged train.${untagged_lang}
    ln -s $valid_tagged valid.${tagging_lang}
    ln -s $valid_untagged valid.${untagged_lang}
    ln -s $test_tagged test.${tagging_lang}
    ln -s $test_untagged test.${untagged_lang}

    fairseq-preprocess \
    --source-lang $src_lang --target-lang $tgt_lang \
    $([ "$has_train" = true ] && echo "--trainpref train" || echo "") \
    --validpref valid --testpref test \
    --thresholdsrc 0 --thresholdtgt 0 \
    --srcdict $tgt_dict --tgtdict $tgt_dict \
    --workers 8 \
    --destdir $bin_dir


}


task TrainModel
    < bin_dir=@BinarizeData
    < src_dict=@
    < tgt_dict=@
    < bpe_model=$spm_model
    < pretrained_model=@
    > model_dir
    :: .submitter=@ .mem=20G .gres="gpu:1" .cpus=3 .time=0
    :: src_lang=@
    :: tgt_lang=@
    :: bpe_type=@
    :: repo=@
    :: seed=@
    :: use_labelsmooth=@
{
    # TODO: parameters are currently hard-coded
    # later we should try to make variable while having a default
    lr=5e-4
    patience=10
    max_epoch=100
    max_tokens=512
    update_freq=1
    arch=transformer_wmt_en_de_big

    fairseq-train \
        $bin_dir \
        --task translation_multi_simple_epoch  \
        --finetune-from-model $pretrained_model \
        --lang-pairs $pretrained_model/language_pairs.txt \
        --max-epoch $max_epoch \
        --log-interval 10 \
        --lang-pairs "en-luo" \
        --arch $arch --share-all-embeddings \
        --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 1.0 \
        --lr $lr --lr-scheduler inverse_sqrt  --warmup-updates 4000 \
        --criterion $([ "$use_labelsmooth" = true ] && echo  "label_smoothed_cross_entropy --label-smoothing 0.1" || echo "cross_entropy") \
        --dropout 0.3 --weight-decay 0.0001 \
        --max-tokens ${max_tokens} --update-freq ${update_freq} \
        --save-interval-updates 1000 --keep-interval-updates	 2 \
        --patience $patience \
        --save-dir $model_dir \
        --seed $seed

    # copy necessary files for a complete checkpoint
    if [ "$bpe_type" = "sentencepiece" ]; then
        ln -s $bpe_model $model_dir/sentencepiece.bpe.model
    elif [ "$bpe_type" = "fastbpe" ]; then
        ln -s $bpe_model $model_dir/bpecodes
    else
        echo "unknown or not supported bpe type"
        exit 1
    fi
    cp $src_dict  $model_dir/dict.${src_lang}.txt
    cp $tgt_dict  $model_dir/dict.${tgt_lang}.txt
    mv $model_dir/checkpoint_best.pt $model_dir/model.pt
    cp $pretrained_model/language_pairs.txt  $model_dir/

}

func GenerateTranslations
    < bin_dir
    < model_dir
    > scores
    > predictions
    :: split
    :: repo
    :: src_lang
    :: tgt_lang
    :: bpe_type
    :: is_multilingual
    :: batch_size
    :: sampling
    :: sampling_topp
    :: diversity_rate
    :: nbest
{
    multilingual_args=""
    if [ "$is_multilingual" = true ]; then
        multilingual_args+="--task translation_multi_simple_epoch "
        multilingual_args+="--decoder-langtok --encoder-langtok src "
        multilingual_args+="--lang-pairs $model_dir/language_pairs.txt "
        multilingual_args+="--fixed-dictionary $model_dir/dict.${src_lang}.txt "
    fi

    fairseq-generate \
        $bin_dir \
        -s $src_lang -t $tgt_lang \
        --gen-subset $split \
        --batch-size $batch_size \
        --path $model_dir/model.pt \
        $multilingual_args \
        --remove-bpe $([ "$bpe_type" = "sentencepiece" ] && echo "sentencepiece" || echo "") \
        $([ "$bpe_type" = "fastbpe" ] && echo "--tokenizer moses" || echo "")  \
        $([ "$sampling" = true ] && echo "--sampling" || echo "") \
        $([ ! -z "$sampling_topp"  ] && echo "--sampling-topp $sampling_topp" || echo "") \
        --diversity-rate $diversity_rate \
        --beam $nbest \
        --nbest $nbest \
            > full_outputs

        cat full_outputs | grep ^H | cut -c 3- | sort -n | cut -f2 > $scores
        cat full_outputs | grep ^H | cut -c 3- | sort -n | cut -f3-  > full_predictions
        awk "NR % 5 == 1" full_predictions > $predictions
        sed  -i 's/<.th>//g' $predictions  #removing the tags that might have been generated
        sed  -i 's/\s//' $predictions #removing the space after tags
}

task GenerateTranslationsValid calls GenerateTranslations
    < bin_dir=@BinarizeData
    < model_dir=(
        UsePretrained:
            true=$pretrained_model
            false=$model_dir@TrainModel
        )
    > scores
    > predictions
    :: .submitter=@ .gres="gpu:1" .cpus=3 .mem=32000M .time=0
    :: split=valid
    :: repo=@
    :: src_lang=@
    :: tgt_lang=@
    :: bpe_type=@
    :: is_multilingual=@
    :: batch_size=@
    :: sampling=@
    :: sampling_topp=@
    :: diversity_rate=@
    :: nbest=@


task GenerateTranslationsTest calls GenerateTranslations
    < bin_dir=@BinarizeData
    < model_dir=(
        UsePretrained:
            true=$pretrained_model
            false=$model_dir@TrainModel
        )
    > scores
    > predictions
    :: .submitter=@ .gres="gpu:1" .cpus=3 .mem=32000M .time=0
    :: split=test
    :: repo=@
    :: src_lang=@
    :: tgt_lang=@
    :: bpe_type=@
    :: is_multilingual=@
    :: batch_size=@
    :: sampling=@
    :: sampling_topp=@
    :: diversity_rate=@
    :: nbest=@

task ScoreTranslationsTest
    < data_dir=@
    < predictions=@GenerateTranslationsTest
    > test_score
    :: .submitter=@ .mem=16000 .gres="gpu:1" .cpus=2
    :: repo=@
    :: src_lang=@
    :: tgt_lang=@
 {
     test_src=$data_dir/test.$src_lang
     test_tgt=$data_dir/test.$tgt_lang
    python $repo/scripts/score.py \
        $predictions $test_tgt --src $test_src > $test_score

 }

task ScoreTranslationsValid
    < data_dir=@
    < valid_predictions=$predictions@GenerateTranslationsValid
    > valid_score
    :: .submitter=@ .mem=16000 .gres="gpu:1" .cpus=2
    :: repo=@
    :: src_lang=@
    :: tgt_lang=@

{
    valid_src=$data_dir/valid.$src_lang
    valid_tgt=$data_dir/valid.$tgt_lang
    python $repo/scripts/score.py \
        $valid_predictions $valid_tgt --src $valid_src > $valid_score
}

summary TranslationQualityTest {
  of ScoreTranslations >  bleu chrf ter  {
    cat $valid_score | grep -oP "BLEU = \K[-0-9.]+" > $bleu
    cat $valid_score | grep -oP "chrF2 = \K[-0-9.]+" > $chrf
    cat $valid_score | grep -oP "TER = \K[-0-9.]+" > $ter
   }
}

