# This script will try to run a task *outside* any specified submitter
# Note: This script is for archival; it is not actually run by ducttape
export pretrained_model="/projects/tir2/users/pfernand/models/flores101_mm100_175M"
export src_dict="/projects/tir6/general/aogayo/models/domaintag/spm/dict.txt"
export bin_dir="/projects/tir6/general/aogayo/workflows-outputs/domaintag-newbpe/BinarizeData/TaggingLang.en/bin_dir"
export tgt_dict="/projects/tir6/general/aogayo/models/domaintag/spm/dict.txt"
export bpe_model="/projects/tir6/general/aogayo/models/domaintag/spm/spm.model"
export model_dir="/projects/tir6/general/aogayo/workflows-outputs/domaintag-newbpe/TrainModel/TaggingLang.en/model_dir"
export submitter="slurm"
export bpe_type="sentencepiece"
export cpus="3"
export gres="gpu:A6000:3"
export mem="60000"
export use_labelsmooth="False"
export tgt_lang="luo"
export src_lang="en"
export repo="/projects/tir6/general/aogayo/models/domaintag"
export time="0"
export seed="9"

    # TODO: parameters are currently hard-coded
    # later we should try to make variable while having a default
    lr=5e-4
    patience=10
    max_epoch=100
    max_tokens=1024
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
        --ddp-backend no_c10d \
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

