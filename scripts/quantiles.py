import numpy as np
import argparse


def get_scores(scores_indomain, scores_multidomain):
    scores = []
    for i in range(len(scores_indomain)):
        scores.append(scores_indomain[i] - scores_multidomain[i])  # difference between the length normalized scores
    return scores


def get_quantiles(scores, n_quantiles, quantiles_file):
    unit_quant = 1 / n_quantiles
    # out_f = open(quantiles_file, "w")
    for i in range(1, n_quantiles):
        thresh = np.quantile(scores, unit_quant * i)
        print(str(thresh) + ",<" + str(i) + "th>")


def assign_quantiles(scores, quant_dict, quant_list, source_file=None, tagged_file=None):
    quants = []
    for i in range(len(scores)):
        for j in range(len(quant_list)):
            if scores[i] <= quant_list [j]:
                if j==0:  #1st
                    quants.append("<0th>")
                else:
                    quants.append(quant_dict[quant_list[j-1]])
                break
            quants.append(quant_dict[quant_list[j - 1]])

            # Printing out
        print(quants[i])
    if source_file and tagged_file:
        '''
            You get the source file with - goal is to add the tag at the beginning
            Example : 
            input: This is the first line
            output: <1st> This is the first line
        '''
        source_lines = open(source_file, "r").readlines()
        assert len(source_lines) == len(scores)
        tagged_out = open(tagged_file, "w"):
        for i in range(len(quants)):
            tagged_out.write(quants[i] + " " + source_lines[i])



def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--scores_indomain", type=str)
    parser.add_argument("--scores_multidomain", type=str)
    parser.add_argument("--n_quantiles", type=int)
    parser.add_argument("--quantiles_file", type=str)
    parser.add_argument("--action", type=str, choices=["get_quantiles", "assign_quantiles"], default="get_quantiles")
    parser.add_argument("--source_file", type=str, default=None)
    parser.add_argument("--tagged_file", type=str, default=None)

    args = parser.parse_args()

    scores_indomain = [float(line.strip()) for line in open(args.scores_indomain, "r").readlines()]
    scores_multidomain = [float(line.strip()) for line in open(args.scores_multidomain, "r").readlines()]
    scores = get_scores(scores_indomain, scores_multidomain)

    if args.action == "get_quantiles":
        get_quantiles(scores, args.n_quantiles, args.quantiles_file)
    elif args.action == "assign_quantiles":
        assert args.quantiles_file is not None, "You need to provide a file with the quantiles"
        quantiles = [line.strip() for line in open(args.quantiles_file, "r").readlines()]
        # TODO - Strong assumption that the quantiles file is sorted
        quant_dict = {}
        quant_list = []
        for line in quantiles:
            split = line.split(",")
            quant_dict[float(split[0])] = split[1]
            quant_list.append(float(split[0]))
        assign_quantiles(scores, quant_dict, quant_list, source_file=args.source_file, tagged_file=args.tagged_file)


if __name__ == "__main__":
    main()
