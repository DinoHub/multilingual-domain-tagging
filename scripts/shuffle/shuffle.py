import argparse
from random import shuffle, seed

'''
Given a dataset, shuffle it  to obtain
inputs :
    fname: name of file
    start: start row to do the shuffling.
    size: fraction of the remaining rows to shuffle if 1 all of them are shuffled
    output (optional) : output file - if not provided it is written to the 
    same file else randomly select and then shuffle.
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("fname", type=str)
    parser.add_argument("start", type=int)  # anything above start is untouched
    parser.add_argument("size", type=float, default=1)
    parser.add_argument("--output", type=str)
    # a500
    # start is 20
    # size is 250

    args = parser.parse_args()

    with open(args.fname, encoding="utf-8") as inp_f:
        lines = [line.strip() for line in inp_f.readlines()]
    seed(3)
    ind_list = [i for i in range(len(lines))]
    start = int(args.start)
    # shuffle_list=
    if args.size != 1:  # pick a subset of it
        shuffle_list = ind_list[start: start + int(args.size)]
    else:
        shuffle_list = ind_list[start:]

    shuffle(shuffle_list)
    new_list = ind_list[:start]
    new_list.extend(shuffle_list)

    # write
    if args.output:
        outfile = open(args.output, "a")
        for idx in new_list:
            outfile.write(lines[idx] + "\n")
    else:
        for idx in new_list:
            print(lines[idx])


if __name__ == "__main__":
    main()
