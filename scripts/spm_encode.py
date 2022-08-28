import sys
import sentencepiece as spm
import os
import argparse
import re

def encode_spm(spm_model: str, text_file: str, out_file: str) -> None:
    """
    """
    sp = spm.SentencePieceProcessor(model_file=spm_model)
    with open(text_file, 'r') as f:
        lines = f.readlines()
    encodings = sp.encode(lines, out_type=str)
    encoded_lines = [' '.join(encoding) + '\n' for encoding in encodings]
    with open(out_file, 'w') as f:
        f.writelines(encoded_lines)
    print("Written sentencepiece encoded text to", out_file, flush=True)
    return


if __name__ == '__main__':
    """
    args:
        input_dir, input_file, out_file, model_name
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('--input_file', type=str,
                        help='Data file path - name of file path  to be encoded',
                        required=False)
    parser.add_argument('--input_dir', type=str,
                        help='Name of directory with files to be encoded',
                        required=False)
    parser.add_argument('--out_file', type=str,
                        help='name of the output file',
                        required=True)
    parser.add_argument('--model_name', type=str,
                        help='Name of spm model',
                        required=True)
    args = parser.parse_args()
    if not (args.input_file or args.input_dir):
        print("You need to specify either a directory or a file to be encoded")
        sys.exit(1)
    if args.input_dir:
        files = []
        for f in os.listdir(args.input_dir):
            full_path = os.path.join(args.input_dir, f)
            if os.path.isfile(full_path):
                files.append(full_path)
        for file in files:
            encode_spm(args.model_name, file, args.out_file)
    elif args.input_file:
        encode_spm(args.model_name, args.input_file, args.out_file)

