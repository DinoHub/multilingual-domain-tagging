import sys


def write_files(lines, out_file):
    for line in lines:
        out_file.write(line)
    out_file.close()


def select(f_name, input, nums):
    others = []
    selected = []
    for i in range(len(input)):
        if i in nums:
            selected.append(input[i])
        else:
            others.append(input[i])
    write_files(others, open(f_name + '.others', "w"))
    write_files(selected, open(f_name + ".selected", "w"))


f1_name = sys.argv[1]
f2_name = sys.argv[2]
fnum_name = sys.argv[3]

lines_f1 = open(f1_name, 'r').readlines()
lines_f2 = open(f2_name, 'r').readlines()
lines_num = [int(num.strip()) for num in open(fnum_name, 'r').readlines()]



assert len(lines_f1) == len(lines_f2), "Files need to have the same number of sentences"

select(f1_name, lines_f1, lines_num)
select(f2_name, lines_f2, lines_num)
print("Doneeeeee!!!!")
