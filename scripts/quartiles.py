import numpy as np
import argparse


def get_quantiles(scores, n_quantiles, quantiles_file):
    # Order the data from smallest to largest
    # Count how many observations you have in your data set
    p = len(scores)
    unit_quant = 1 / n_quantiles
    out_f = open(quantiles_file, "w")
    for i in range(1, n_quantiles):
        thresh = np.quantile(scores, unit_quant * i)
        out_f.write(str(thresh) + "," + str(i) + "th\n")


def assign_quantiles(scores, quant_dict, quant_list, out_file=None):
    quants = []
    for score in scores:
        for i in range(len(quant_list)):
            if i == 0:
                if score < quant_list[i]:
                    quants.append("0th")
            if score >= quant_list[i]:
                quants.append(quant_dict[quant_list[i]])

    for quant_tag in quants:
        print(quant_tag)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--scores_file", type=str)
    parser.add_argument("--n_quantiles", type=int)
    parser.add_argument("--quantiles_file", type=str)
    parser.add_argument("--action", type=str, choices=["get_quantiles", "assign_quantiles"], default="get_quantiles")

    args = parser.parse_args()

    scores = [float(line.strip()) for line in open(args.scores_file, "r").readlines()]
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
        assign_quantiles(scores, quant_dict, quant_list)


if __name__ == "__main__":
    main()
